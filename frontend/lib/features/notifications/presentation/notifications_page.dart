import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_leading_button.dart';
import '../application/notification_controller.dart';
import '../data/notification_models.dart';

/// 백엔드가 알림 content를 한국어 문장으로 직접 생성해서 내려준다
/// (app/tasks/notification_tasks.py). 프론트에서 재번역할 수 없으니,
/// "{이름}님이 ..." 패턴에서 이름만 뽑아 앱 자체 번역 템플릿으로 다시 렌더링한다.
/// 백엔드가 문장 형식을 바꾸면 이 파싱도 같이 깨지니 주의.
String _localizedNotificationContent(AppNotification n) {
  final name = n.content.split('님이').first.trim();
  final matched = name.isNotEmpty && name != n.content;
  if (matched && n.type == 'card_assigned') {
    return 'notification.assignedMessage'.tr(namedArgs: {'name': name});
  }
  if (matched && n.type == 'comment') {
    return 'notification.commentMessage'.tr(namedArgs: {'name': name});
  }
  return n.content;
}

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    // 백엔드에 알림 WebSocket push가 아직 없어서(HANDOFF.md 5-2 참고) 폴링으로 대체.
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      ref.read(notificationControllerProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.ink50,
      appBar: AppBar(
        leading: const BackLeadingButton(fallbackPath: '/'),
        title: Text('notification.title'.tr()),
        actions: [
          TextButton(
            onPressed: () => ref.read(notificationControllerProvider.notifier).markAllAsRead(),
            child: Text('notification.markAllRead'.tr()),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(error is ApiException ? error.message : 'common.unknownError'.tr()),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.notifications_none_outlined,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'notification.empty'.tr(),
                    style: const TextStyle(color: AppColors.ink500),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(notificationControllerProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final n = notifications[index];
                final isAssigned = n.type == 'card_assigned';
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: n.isRead ? AppColors.surface : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: n.isRead ? AppColors.ink200 : AppColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.ink200),
                        ),
                        child: Icon(
                          isAssigned ? Icons.assignment_ind_outlined : Icons.chat_bubble_outline,
                          size: 17,
                          color: n.isRead ? AppColors.ink300 : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _localizedNotificationContent(n),
                              style: TextStyle(
                                fontSize: 13.5,
                                color: AppColors.ink900,
                                fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('yyyy-MM-dd HH:mm').format(n.createdAt),
                              style: const TextStyle(fontSize: 11.5, color: AppColors.ink300),
                            ),
                          ],
                        ),
                      ),
                      if (!n.isRead)
                        TextButton(
                          onPressed: () =>
                              ref.read(notificationControllerProvider.notifier).markAsRead(n.id),
                          child: Text('notification.markRead'.tr()),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
