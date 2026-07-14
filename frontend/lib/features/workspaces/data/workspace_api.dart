import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/dio_client.dart';
import 'workspace_models.dart';

class WorkspaceApi {
  WorkspaceApi(this._dio);

  final Dio _dio;

  /// 백엔드가 배열을 그대로 반환함 (페이지네이션 미적용, 실제 응답으로 확인됨)
  Future<List<Workspace>> getWorkspaces() async {
    try {
      final response = await _dio.get('/workspaces/');
      return (response.data as List)
          .map((e) => Workspace.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Workspace> createWorkspace(String name) async {
    try {
      final response = await _dio.post('/workspaces/', data: {'name': name});
      return Workspace.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteWorkspace(int workspaceId) async {
    try {
      await _dio.delete('/workspaces/$workspaceId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// 멤버가 없을 리 없지만(생성 시 owner가 자동 추가됨), 방어적으로 404는 빈 목록 취급.
  Future<List<WorkspaceMember>> getMembers(int workspaceId) async {
    try {
      final response = await _dio.get('/workspaces/$workspaceId/members');
      return (response.data as List)
          .map((e) => WorkspaceMember.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> inviteMember({
    required int workspaceId,
    required String email,
    required String role,
  }) async {
    try {
      await _dio.post(
        '/workspaces/$workspaceId/members',
        data: {'email': email, 'role': role},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

final workspaceApiProvider = Provider<WorkspaceApi>((ref) {
  return WorkspaceApi(ref.watch(dioProvider));
});
