import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/signup_page.dart';
import '../../features/boards/presentation/board_detail_page.dart';
import '../../features/boards/presentation/board_list_page.dart';
import '../../features/notifications/presentation/notifications_page.dart';
import '../../features/workspaces/presentation/workspace_list_page.dart';

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Ref ref) {
    ref.listen(authControllerProvider, (previous, next) {
      notifyListeners();
    });
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final authListenable = _AuthRefreshListenable(ref);
  ref.onDispose(authListenable.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      if (authState.isLoading) return null;

      final isLoggedIn = authState.value != null;
      final loggingInRoute =
          state.matchedLocation == '/login' || state.matchedLocation == '/signup';

      if (!isLoggedIn && !loggingInRoute) return '/login';
      if (isLoggedIn && loggingInRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
      GoRoute(path: '/', builder: (context, state) => const WorkspaceListPage()),
      GoRoute(
        path: '/workspaces/:workspaceId/boards',
        builder: (context, state) => BoardListPage(
          workspaceId: int.parse(state.pathParameters['workspaceId']!),
        ),
      ),
      GoRoute(
        path: '/workspaces/:workspaceId/boards/:boardId',
        builder: (context, state) => BoardDetailPage(
          workspaceId: int.parse(state.pathParameters['workspaceId']!),
          boardId: int.parse(state.pathParameters['boardId']!),
        ),
      ),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsPage()),
    ],
  );
});
