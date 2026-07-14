class AppNotification {
  AppNotification({
    required this.id,
    required this.type,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.cardId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      type: json['type'] as String,
      content: json['content'] as String,
      isRead: json['is_read'] as bool,
      cardId: json['card_id'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final int id;
  final String type;
  final String content;
  final bool isRead;
  final int? cardId;
  final DateTime createdAt;
}
