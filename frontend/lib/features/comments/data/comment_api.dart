import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/paginated_response.dart';
import 'comment_models.dart';

class CommentApi {
  CommentApi(this._dio);

  final Dio _dio;

  Future<PaginatedResponse<Comment>> getComments(int cardId) async {
    try {
      final response = await _dio.get('/cards/$cardId/comments');
      return PaginatedResponse.fromJson(
        response.data as Map<String, dynamic>,
        Comment.fromJson,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Comment> createComment({
    required int cardId,
    required String content,
  }) async {
    try {
      final response = await _dio.post(
        '/cards/$cardId/comments',
        data: {'content': content},
      );
      return Comment.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteComment(int commentId) async {
    try {
      await _dio.delete('/comments/$commentId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

final commentApiProvider = Provider<CommentApi>((ref) {
  return CommentApi(ref.watch(dioProvider));
});
