import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/paginated_response.dart';
import 'board_models.dart';

class BoardApi {
  BoardApi(this._dio);

  final Dio _dio;

  Future<PaginatedResponse<Board>> getBoards(int workspaceId) async {
    try {
      final response = await _dio.get('/workspaces/$workspaceId/boards/');
      return PaginatedResponse.fromJson(
        response.data as Map<String, dynamic>,
        Board.fromJson,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Board> createBoard({
    required int workspaceId,
    required String name,
  }) async {
    try {
      final response = await _dio.post(
        '/workspaces/$workspaceId/boards/',
        data: {'name': name},
      );
      return Board.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<BoardDetail> getBoardDetail({
    required int workspaceId,
    required int boardId,
  }) async {
    try {
      final response = await _dio.get(
        '/workspaces/$workspaceId/boards/$boardId',
      );
      return BoardDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteBoard({
    required int workspaceId,
    required int boardId,
  }) async {
    try {
      await _dio.delete('/workspaces/$workspaceId/boards/$boardId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ListWithCards> createList({
    required int boardId,
    required String title,
  }) async {
    try {
      final response = await _dio.post(
        '/boards/$boardId/lists',
        data: {'title': title},
      );
      final json = response.data as Map<String, dynamic>;
      return ListWithCards(
        id: json['id'] as int,
        boardId: json['board_id'] as int,
        title: json['title'] as String,
        position: (json['position'] as num).toDouble(),
        cards: const [],
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteList(int listId) async {
    try {
      await _dio.delete('/lists/$listId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

final boardApiProvider = Provider<BoardApi>((ref) {
  return BoardApi(ref.watch(dioProvider));
});
