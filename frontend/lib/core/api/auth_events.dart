import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// dio 인터셉터(core 계층)가 refresh token 회전 실패를 감지했을 때,
/// auth 기능 계층에 "강제 로그아웃"을 알리기 위한 이벤트 버스.
/// core -> features 방향 의존을 피하려고 이렇게 분리함.
final forceLogoutControllerProvider = Provider<StreamController<void>>((ref) {
  final controller = StreamController<void>.broadcast();
  ref.onDispose(controller.close);
  return controller;
});

final forceLogoutStreamProvider = StreamProvider<void>((ref) {
  return ref.watch(forceLogoutControllerProvider).stream;
});
