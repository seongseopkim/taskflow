import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';

/// FastAPI 기본 에러 포맷 {"detail": "..."} 을 사람이 읽을 메시지로 변환.
/// 백엔드 detail 메시지는 서버가 내려주는 그대로 노출한다(번역 대상 아님).
/// 아래 두 fallback 메시지는 순수 클라이언트 문구라 tr()로 다국어 처리한다.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiException.fromDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) {
      return ApiException(data['detail'].toString(), statusCode: statusCode);
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return ApiException(tr('errors.connectionFailed'), statusCode: statusCode);
    }
    return ApiException(e.message ?? tr('common.unknownError'), statusCode: statusCode);
  }

  @override
  String toString() => message;
}
