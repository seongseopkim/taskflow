import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/dio_client.dart';
import 'card_models.dart';

class CardApi {
  CardApi(this._dio);

  final Dio _dio;

  Future<CardModel> createCard({
    required int listId,
    required String title,
    String? description,
    int? assigneeId,
    DateTime? dueDate,
  }) async {
    try {
      final response = await _dio.post(
        '/lists/$listId/cards',
        data: {
          'title': title,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (assigneeId != null) 'assignee_id': assigneeId,
          if (dueDate != null) 'due_date': dueDate.toIso8601String(),
        },
      );
      return CardModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<CardModel> updateCard({
    required int cardId,
    String? title,
    String? description,
    int? assigneeId,
    DateTime? dueDate,
  }) async {
    try {
      final response = await _dio.patch(
        '/cards/$cardId',
        data: {
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (assigneeId != null) 'assignee_id': assigneeId,
          if (dueDate != null) 'due_date': dueDate.toIso8601String(),
        },
      );
      return CardModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<CardModel> moveCard({
    required int cardId,
    required int targetListId,
    required double position,
  }) async {
    try {
      final response = await _dio.patch(
        '/cards/$cardId/move',
        data: {'target_list_id': targetListId, 'position': position},
      );
      return CardModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteCard(int cardId) async {
    try {
      await _dio.delete('/cards/$cardId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

final cardApiProvider = Provider<CardApi>((ref) {
  return CardApi(ref.watch(dioProvider));
});
