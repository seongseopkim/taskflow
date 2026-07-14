import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/paginated_response.dart';
import 'label_models.dart';

class LabelApi {
  LabelApi(this._dio);

  final Dio _dio;

  Future<PaginatedResponse<Label>> getLabels(int boardId) async {
    try {
      final response = await _dio.get('/boards/$boardId/labels');
      return PaginatedResponse.fromJson(
        response.data as Map<String, dynamic>,
        Label.fromJson,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Label> createLabel({
    required int boardId,
    required String name,
    required String color,
  }) async {
    try {
      final response = await _dio.post(
        '/boards/$boardId/labels',
        data: {'name': name, 'color': color},
      );
      return Label.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> attachLabel({required int cardId, required int labelId}) async {
    try {
      await _dio.post('/cards/$cardId/labels/$labelId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> detachLabel({required int cardId, required int labelId}) async {
    try {
      await _dio.delete('/cards/$cardId/labels/$labelId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

final labelApiProvider = Provider<LabelApi>((ref) {
  return LabelApi(ref.watch(dioProvider));
});
