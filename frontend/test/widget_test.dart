import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taskflow_frontend/core/storage/token_storage.dart';
import 'package:taskflow_frontend/main.dart';

/// flutter_tester(macOS 헤드리스) 환경에서 실제 FlutterSecureStorage를 쓰면
/// Keychain 접근 때문에 테스트가 영원히 멈춘다. 테스트에서는 메모리로 대체.
class FakeTokenStorage extends TokenStorage {
  FakeTokenStorage() : super(const FlutterSecureStorage());

  final Map<String, String> _store = {};

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _store['access_token'] = accessToken;
    _store['refresh_token'] = refreshToken;
  }

  @override
  Future<void> saveProfile({
    required int userId,
    required String email,
    String? name,
  }) async {
    _store['user_id'] = userId.toString();
    _store['user_email'] = email;
    if (name != null) _store['user_name'] = name;
  }

  @override
  Future<String?> readAccessToken() async => _store['access_token'];

  @override
  Future<String?> readRefreshToken() async => _store['refresh_token'];

  @override
  Future<Map<String, String?>> readProfile() async => {
    'id': _store['user_id'],
    'email': _store['user_email'],
    'name': _store['user_name'],
  };

  @override
  Future<void> clear() async => _store.clear();
}

void main() {
  testWidgets('App boots and shows the login screen', (WidgetTester tester) async {
    await EasyLocalization.ensureInitialized();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tokenStorageProvider.overrideWithValue(FakeTokenStorage())],
        child: EasyLocalization(
          supportedLocales: const [Locale('ko'), Locale('ja')],
          path: 'assets/translations',
          fallbackLocale: const Locale('ko'),
          startLocale: const Locale('ko'),
          child: const TaskFlowApp(),
        ),
      ),
    );

    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(tester.takeException(), isNull);
    expect(find.text('auth.loginTitle'.tr()), findsOneWidget);
  });
}
