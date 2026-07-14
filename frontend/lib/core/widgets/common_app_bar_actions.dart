import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../theme/app_theme.dart';

/// 모든 주요 화면 AppBar에 붙는 공통 액션: 언어 전환, 알림, 로그아웃.
class CommonAppBarActions extends ConsumerWidget {
  const CommonAppBarActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PopupMenuButton<Locale>(
          tooltip: 'KO / JA',
          onSelected: (locale) => context.setLocale(locale),
          icon: const Icon(Icons.language_outlined),
          itemBuilder: (context) => const [
            PopupMenuItem(value: Locale('ko'), child: Text('한국어')),
            PopupMenuItem(value: Locale('ja'), child: Text('日本語')),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'notification.title'.tr(),
          onPressed: () => context.push('/notifications'),
        ),
        const SizedBox(width: 4),
        IconButton(
          style: IconButton.styleFrom(foregroundColor: AppColors.ink500),
          icon: const Icon(Icons.logout_outlined),
          tooltip: 'common.logout'.tr(),
          onPressed: () async {
            await ref.read(authControllerProvider.notifier).logout();
          },
        ),
      ],
    );
  }
}
