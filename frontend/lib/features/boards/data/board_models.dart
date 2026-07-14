import '../../cards/data/card_models.dart';

class Board {
  Board({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.createdAt,
  });

  factory Board.fromJson(Map<String, dynamic> json) {
    return Board(
      id: json['id'] as int,
      workspaceId: json['workspace_id'] as int,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final int id;
  final int workspaceId;
  final String name;
  final DateTime createdAt;
}

class ListWithCards {
  ListWithCards({
    required this.id,
    required this.boardId,
    required this.title,
    required this.position,
    required this.cards,
  });

  factory ListWithCards.fromJson(Map<String, dynamic> json) {
    return ListWithCards(
      id: json['id'] as int,
      boardId: json['board_id'] as int,
      title: json['title'] as String,
      position: (json['position'] as num).toDouble(),
      cards: (json['cards'] as List)
          .map((e) => CardModel.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.position.compareTo(b.position)),
    );
  }

  final int id;
  final int boardId;
  final String title;
  final double position;
  final List<CardModel> cards;

  ListWithCards copyWith({List<CardModel>? cards}) {
    return ListWithCards(
      id: id,
      boardId: boardId,
      title: title,
      position: position,
      cards: cards ?? this.cards,
    );
  }
}

class BoardDetail {
  BoardDetail({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.createdAt,
    required this.lists,
  });

  factory BoardDetail.fromJson(Map<String, dynamic> json) {
    return BoardDetail(
      id: json['id'] as int,
      workspaceId: json['workspace_id'] as int,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      lists: (json['lists'] as List)
          .map((e) => ListWithCards.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.position.compareTo(b.position)),
    );
  }

  final int id;
  final int workspaceId;
  final String name;
  final DateTime createdAt;
  final List<ListWithCards> lists;

  BoardDetail copyWith({List<ListWithCards>? lists}) {
    return BoardDetail(
      id: id,
      workspaceId: workspaceId,
      name: name,
      createdAt: createdAt,
      lists: lists ?? this.lists,
    );
  }
}
