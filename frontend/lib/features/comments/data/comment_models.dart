class Comment {
  Comment({
    required this.id,
    required this.cardId,
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as int,
      cardId: json['card_id'] as int,
      userId: json['user_id'] as int,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final int id;
  final int cardId;
  final int userId;
  final String content;
  final DateTime createdAt;
}
