import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/workspace_api.dart';
import '../data/workspace_models.dart';

/// 카드 담당자 선택 드롭다운 등에서 쓰는 읽기 전용 워크스페이스 멤버 목록.
final workspaceMembersProvider =
    FutureProvider.family<List<WorkspaceMember>, int>((ref, workspaceId) {
  return ref.read(workspaceApiProvider).getMembers(workspaceId);
});
