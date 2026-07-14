import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notification_api.dart';
import '../data/notification_models.dart';

class NotificationController extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() async {
    final result = await ref.read(notificationApiProvider).getNotifications();
    return result.items;
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final result =
          await ref.read(notificationApiProvider).getNotifications();
      return result.items;
    });
  }

  Future<void> markAsRead(int notificationId) async {
    await ref.read(notificationApiProvider).markAsRead(notificationId);
    await refresh();
  }

  Future<void> markAllAsRead() async {
    await ref.read(notificationApiProvider).markAllAsRead();
    await refresh();
  }
}

final notificationControllerProvider =
    AsyncNotifierProvider<NotificationController, List<AppNotification>>(
      NotificationController.new,
    );

/// 안 읽은 알림 개수 - 앱바 배지 표시용
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationControllerProvider).value ?? [];
  return notifications.where((n) => !n.isRead).length;
});
