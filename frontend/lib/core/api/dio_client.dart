import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/token_storage.dart';
import 'api_config.dart';
import 'auth_events.dart';

/// 로그인/회원가입/refresh 호출 전용. 인증 인터셉터가 없어서
/// refresh 실패 시 무한루프에 빠지지 않는다.
final rawDioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
});

/// 나머지 모든 API 호출에 쓰는 dio. Access token을 자동으로 붙이고,
/// 401을 받으면 refresh token으로 1회 재발급 시도 후 원 요청을 재시도한다.
/// (백엔드가 refresh token rotation을 쓰므로 재발급 응답의 새 refresh_token으로
/// 반드시 덮어써야 함 — 안 그러면 다음 refresh 때 401이 남)
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
  final tokenStorage = ref.watch(tokenStorageProvider);
  final rawDio = ref.watch(rawDioProvider);

  Completer<bool>? refreshCompleter;

  Future<bool> refreshTokens() async {
    if (refreshCompleter != null) {
      return refreshCompleter!.future;
    }
    final completer = Completer<bool>();
    refreshCompleter = completer;
    try {
      final refreshToken = await tokenStorage.readRefreshToken();
      if (refreshToken == null) {
        completer.complete(false);
        return false;
      }
      final response = await rawDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final newAccess = response.data['access_token'] as String;
      final newRefresh = response.data['refresh_token'] as String;
      await tokenStorage.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );
      completer.complete(true);
      return true;
    } catch (_) {
      completer.complete(false);
      return false;
    } finally {
      refreshCompleter = null;
    }
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final accessToken = await tokenStorage.readAccessToken();
        if (accessToken != null) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final isUnauthorized = error.response?.statusCode == 401;
        final alreadyRetried = error.requestOptions.extra['retried'] == true;

        if (!isUnauthorized || alreadyRetried) {
          handler.next(error);
          return;
        }

        final refreshed = await refreshTokens();
        if (!refreshed) {
          await tokenStorage.clear();
          ref.read(forceLogoutControllerProvider).add(null);
          handler.next(error);
          return;
        }

        try {
          final newAccessToken = await tokenStorage.readAccessToken();
          final retryOptions = error.requestOptions;
          retryOptions.extra['retried'] = true;
          retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          final response = await dio.fetch(retryOptions);
          handler.resolve(response);
        } catch (e) {
          handler.next(error);
        }
      },
    ),
  );

  return dio;
});
