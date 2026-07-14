class Label {
  Label({
    required this.id,
    required this.boardId,
    required this.name,
    required this.color,
  });

  factory Label.fromJson(Map<String, dynamic> json) {
    return Label(
      id: json['id'] as int,
      boardId: json['board_id'] as int,
      name: json['name'] as String,
      color: json['color'] as String,
    );
  }

  final int id;
  final int boardId;
  final String name;
  final String color;
}
