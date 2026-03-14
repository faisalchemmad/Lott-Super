class NumberLimitModel {
  final int id;
  final int game;
  final String gameName;
  final int user;
  final String userUsername;
  final String number;
  final String type;
  final int maxCount;

  NumberLimitModel({
    required this.id,
    required this.game,
    this.gameName = '',
    required this.user,
    this.userUsername = '',
    required this.number,
    required this.type,
    this.maxCount = 50,
  });

  factory NumberLimitModel.fromJson(Map<String, dynamic> json) {
    return NumberLimitModel(
      id: json['id'],
      game: json['game'],
      gameName: json['game_name'] ?? '',
      user: json['user'],
      userUsername: json['user_username'] ?? '',
      number: json['number'],
      type: json['type'],
      maxCount: json['max_count'] ?? 50,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'game': game,
      'user': user,
      'number': number,
      'type': type,
      'max_count': maxCount,
    };
  }
}
