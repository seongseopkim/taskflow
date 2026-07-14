class ApiConfig {
  ApiConfig._();

  /// 개발 환경 기본값. 배포 시 --dart-define=API_BASE_URL=... 로 덮어쓸 수 있음.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'ws://localhost:8000',
  );
}
