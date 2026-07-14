class Workspace {
  Workspace({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.createdAt,
  });

  factory Workspace.fromJson(Map<String, dynamic> json) {
    return Workspace(
      id: json['id'] as int,
      ownerId: json['owner_id'] as int,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final int id;
  final int ownerId;
  final String name;
  final DateTime createdAt;
}

class WorkspaceMember {
  WorkspaceMember({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
  });

  factory WorkspaceMember.fromJson(Map<String, dynamic> json) {
    return WorkspaceMember(
      userId: json['user_id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
    );
  }

  final int userId;
  final String name;
  final String email;
  final String role;
}
