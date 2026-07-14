import 'dart:convert';

/// 백엔드가 프로필 조회 API를 제공하지 않아서, access token의 sub 클레임에서
/// user id를 직접 꺼내 쓴다. (app/core/security.py: payload = {"sub": str(user_id), ...})
int? userIdFromAccessToken(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final normalized = base64Url.normalize(parts[1]);
    final payload = json.decode(utf8.decode(base64Url.decode(normalized)));
    final sub = payload['sub'];
    if (sub == null) return null;
    return int.tryParse(sub.toString());
  } catch (_) {
    return null;
  }
}
