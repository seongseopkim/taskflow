class UserSession {
  const UserSession({required this.id, required this.email, this.name});

  final int id;
  final String email;
  final String? name;

  String get displayName => name ?? email;
}
