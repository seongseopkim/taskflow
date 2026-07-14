import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/workspace_api.dart';
import '../data/workspace_models.dart';

class WorkspaceController extends AsyncNotifier<List<Workspace>> {
  @override
  Future<List<Workspace>> build() {
    return ref.read(workspaceApiProvider).getWorkspaces();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(workspaceApiProvider).getWorkspaces(),
    );
  }

  Future<void> createWorkspace(String name) async {
    await ref.read(workspaceApiProvider).createWorkspace(name);
    await refresh();
  }

  Future<void> deleteWorkspace(int workspaceId) async {
    await ref.read(workspaceApiProvider).deleteWorkspace(workspaceId);
    await refresh();
  }

  Future<void> inviteMember({
    required int workspaceId,
    required String email,
    required String role,
  }) {
    return ref
        .read(workspaceApiProvider)
        .inviteMember(workspaceId: workspaceId, email: email, role: role);
  }
}

final workspaceControllerProvider =
    AsyncNotifierProvider<WorkspaceController, List<Workspace>>(
      WorkspaceController.new,
    );
