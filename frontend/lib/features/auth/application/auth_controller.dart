import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/auth_events.dart';
import '../../../core/api/jwt_utils.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_api.dart';
import '../domain/user_session.dart';

class AuthController extends AsyncNotifier<UserSession?> {
  @override
  Future<UserSession?> build() async {
    ref.listen(forceLogoutStreamProvider, (previous, next) {
      state = const AsyncValue.data(null);
    });

    final tokenStorage = ref.watch(tokenStorageProvider);
    final accessToken = await tokenStorage.readAccessToken();
    if (accessToken == null) return null;

    final profile = await tokenStorage.readProfile();
    final id = int.tryParse(profile['id'] ?? '');
    final email = profile['email'];
    if (id == null || email == null) {
      await tokenStorage.clear();
      return null;
    }
    return UserSession(id: id, email: email, name: profile['name']);
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final tokenStorage = ref.read(tokenStorageProvider);
      try {
        final data = await ref
            .read(authApiProvider)
            .login(email: email, password: password);
        final accessToken = data['access_token'] as String;
        final refreshToken = data['refresh_token'] as String;
        await tokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        final id = userIdFromAccessToken(accessToken);
        if (id == null) {
          throw ApiException(tr('errors.invalidTokenFormat'));
        }
        await tokenStorage.saveProfile(userId: id, email: email);
        return UserSession(id: id, email: email);
      } on DioException catch (e) {
        throw ApiException.fromDioException(e);
      }
    });
  }

  Future<void> signup({
    required String email,
    required String password,
    required String name,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final tokenStorage = ref.read(tokenStorageProvider);
      try {
        final data = await ref
            .read(authApiProvider)
            .signup(email: email, password: password, name: name);
        final accessToken = data['access_token'] as String;
        final refreshToken = data['refresh_token'] as String;
        await tokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        final id = userIdFromAccessToken(accessToken);
        if (id == null) {
          throw ApiException(tr('errors.invalidTokenFormat'));
        }
        await tokenStorage.saveProfile(userId: id, email: email, name: name);
        return UserSession(id: id, email: email, name: name);
      } on DioException catch (e) {
        throw ApiException.fromDioException(e);
      }
    });
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).clear();
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, UserSession?>(AuthController.new);
