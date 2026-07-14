import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/label_api.dart';
import '../data/label_models.dart';

class LabelController extends AsyncNotifier<List<Label>> {
  LabelController(this.boardId);

  final int boardId;

  @override
  Future<List<Label>> build() async {
    final result = await ref.read(labelApiProvider).getLabels(boardId);
    return result.items;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(labelApiProvider).getLabels(boardId);
      return result.items;
    });
  }

  Future<void> createLabel({required String name, required String color}) async {
    await ref
        .read(labelApiProvider)
        .createLabel(boardId: boardId, name: name, color: color);
    await refresh();
  }
}

final labelControllerProvider =
    AsyncNotifierProvider.family<LabelController, List<Label>, int>(
      (boardId) => LabelController(boardId),
    );

/// 백엔드에 "카드에 붙은 라벨 조회" API가 없어서(POST/DELETE만 존재),
/// 이번 세션에서 부착/제거한 라벨만 로컬로 추적한다.
/// 앱을 재시작하면 초기화되는 임시방편 — 백엔드에 조회 API 추가가 필요함.
class CardLabelState extends Notifier<Set<int>> {
  CardLabelState(this.cardId);

  final int cardId;

  @override
  Set<int> build() => <int>{};

  Future<void> attach(int labelId) async {
    await ref
        .read(labelApiProvider)
        .attachLabel(cardId: cardId, labelId: labelId);
    state = {...state, labelId};
  }

  Future<void> detach(int labelId) async {
    await ref
        .read(labelApiProvider)
        .detachLabel(cardId: cardId, labelId: labelId);
    state = {...state}..remove(labelId);
  }
}

final cardLabelStateProvider =
    NotifierProvider.family<CardLabelState, Set<int>, int>(
      (cardId) => CardLabelState(cardId),
    );
