import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cards/data/card_api.dart';
import '../data/board_api.dart';
import '../data/board_models.dart';

typedef BoardDetailArg = ({int workspaceId, int boardId});

class BoardDetailController extends AsyncNotifier<BoardDetail> {
  BoardDetailController(this.arg);

  final BoardDetailArg arg;

  @override
  Future<BoardDetail> build() {
    return ref
        .read(boardApiProvider)
        .getBoardDetail(workspaceId: arg.workspaceId, boardId: arg.boardId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(boardApiProvider)
          .getBoardDetail(workspaceId: arg.workspaceId, boardId: arg.boardId),
    );
  }

  Future<void> createList(String title) async {
    await ref.read(boardApiProvider).createList(boardId: arg.boardId, title: title);
    await refresh();
  }

  Future<void> deleteList(int listId) async {
    await ref.read(boardApiProvider).deleteList(listId);
    await refresh();
  }

  Future<void> createCard({required int listId, required String title}) async {
    await ref.read(cardApiProvider).createCard(listId: listId, title: title);
    await refresh();
  }

  /// 드래그앤드롭으로 카드를 옮길 때: 낙관적으로 로컬 상태를 먼저 갱신해
  /// 화면이 즉시 반응하게 하고, API 호출이 실패하면 서버 상태로 되돌린다.
  Future<void> moveCard({
    required int cardId,
    required int fromListId,
    required int toListId,
    required double newPosition,
  }) async {
    final current = state.value;
    if (current == null) return;

    final lists = current.lists;
    final fromIndex = lists.indexWhere((l) => l.id == fromListId);
    final toIndex = lists.indexWhere((l) => l.id == toListId);
    if (fromIndex == -1 || toIndex == -1) return;

    final movingCard = lists[fromIndex].cards.firstWhere((c) => c.id == cardId);
    final updatedCard = movingCard.copyWith(
      listId: toListId,
      position: newPosition,
    );

    final newLists = [...lists];
    newLists[fromIndex] = lists[fromIndex].copyWith(
      cards: lists[fromIndex].cards.where((c) => c.id != cardId).toList(),
    );
    final targetListIndex = newLists.indexWhere((l) => l.id == toListId);
    final targetCards = [...newLists[targetListIndex].cards, updatedCard]
      ..sort((a, b) => a.position.compareTo(b.position));
    newLists[targetListIndex] = newLists[targetListIndex].copyWith(
      cards: targetCards,
    );

    state = AsyncValue.data(current.copyWith(lists: newLists));

    try {
      await ref
          .read(cardApiProvider)
          .moveCard(cardId: cardId, targetListId: toListId, position: newPosition);
    } catch (_) {
      await refresh();
      rethrow;
    }
  }
}

final boardDetailControllerProvider = AsyncNotifierProvider.family<
    BoardDetailController, BoardDetail, BoardDetailArg>(
  (arg) => BoardDetailController(arg),
);
