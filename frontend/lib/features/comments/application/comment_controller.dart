import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/comment_api.dart';
import '../data/comment_models.dart';

class CommentController extends AsyncNotifier<List<Comment>> {
  CommentController(this.cardId);

  final int cardId;

  @override
  Future<List<Comment>> build() async {
    final result = await ref.read(commentApiProvider).getComments(cardId);
    return result.items;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(commentApiProvider).getComments(cardId);
      return result.items;
    });
  }

  Future<void> addComment(String content) async {
    await ref
        .read(commentApiProvider)
        .createComment(cardId: cardId, content: content);
    await refresh();
  }

  Future<void> deleteComment(int commentId) async {
    await ref.read(commentApiProvider).deleteComment(commentId);
    await refresh();
  }
}

final commentControllerProvider =
    AsyncNotifierProvider.family<CommentController, List<Comment>, int>(
      (cardId) => CommentController(cardId),
    );
