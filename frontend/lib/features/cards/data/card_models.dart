class CardModel {
  CardModel({
    required this.id,
    required this.listId,
    required this.title,
    required this.position,
    required this.createdAt,
    this.description,
    this.assigneeId,
    this.dueDate,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'] as int,
      listId: json['list_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      assigneeId: json['assignee_id'] as int?,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      position: (json['position'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final int id;
  final int listId;
  final String title;
  final String? description;
  final int? assigneeId;
  final DateTime? dueDate;
  final double position;
  final DateTime createdAt;

  CardModel copyWith({
    int? listId,
    String? title,
    String? description,
    int? assigneeId,
    DateTime? dueDate,
    double? position,
  }) {
    return CardModel(
      id: id,
      listId: listId ?? this.listId,
      title: title ?? this.title,
      description: description ?? this.description,
      assigneeId: assigneeId ?? this.assigneeId,
      dueDate: dueDate ?? this.dueDate,
      position: position ?? this.position,
      createdAt: createdAt,
    );
  }
}
