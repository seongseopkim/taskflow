import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/paginated_response.dart';
import 'notification_models.dart';

class NotificationApi {
  NotificationApi(this._dio);

  final Dio _dio;

  Future<PaginatedResponse<AppNotification>> getNotifications({
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(
        '/notifications/',
        queryParameters: {'page': page},
      );
      return PaginatedResponse.fromJson(
        response.data as Map<String, dynamic>,
        AppNotification.fromJson,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await _dio.patch('/notifications/$notificationId/read');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _dio.patch('/notifications/read-all');
    } on DioException catch (e) {
      // 알림이 0개면 백엔드가 404를 던짐 - 사용자에게는 에러가 아니므로 무시
      if (e.response?.statusCode != 404) {
        throw ApiException.fromDioException(e);
      }
    }
  }
}

final notificationApiProvider = Provider<NotificationApi>((ref) {
  return NotificationApi(ref.watch(dioProvider));
});
