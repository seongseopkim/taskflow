import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/board_api.dart';
import '../data/board_models.dart';

class BoardListController extends AsyncNotifier<List<Board>> {
  BoardListController(this.workspaceId);

  final int workspaceId;

  @override
  Future<List<Board>> build() async {
    final result = await ref.read(boardApiProvider).getBoards(workspaceId);
    return result.items;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(boardApiProvider).getBoards(workspaceId);
      return result.items;
    });
  }

  Future<void> createBoard(String name) async {
    await ref
        .read(boardApiProvider)
        .createBoard(workspaceId: workspaceId, name: name);
    await refresh();
  }

  Future<void> deleteBoard(int boardId) async {
    await ref
        .read(boardApiProvider)
        .deleteBoard(workspaceId: workspaceId, boardId: boardId);
    await refresh();
  }
}

final boardListControllerProvider =
    AsyncNotifierProvider.family<BoardListController, List<Board>, int>(
      (workspaceId) => BoardListController(workspaceId),
    );
