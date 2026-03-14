class BetModel {
  final int id;
  final String number;
  final double amount;
  final int count;
  final String type;
  final String gameName;
  final String gameTime;
  final String? username;
  final DateTime createdAt;

  final double totalAmount;
  final double commission;
  final double netAmount;
  final bool? gameCanEditDelete;
  final String? gameEditDeleteLimitTime;

  BetModel({
    required this.id,
    required this.number,
    required this.amount,
    required this.count,
    required this.type,
    required this.gameName,
    required this.gameTime,
    this.username,
    required this.createdAt,
    this.totalAmount = 0.0,
    this.commission = 0.0,
    this.netAmount = 0.0,
    this.gameCanEditDelete,
    this.gameEditDeleteLimitTime,
  });

  factory BetModel.fromJson(Map<String, dynamic> json) {
    return BetModel(
      id: json['id'],
      number: json['number'],
      amount: double.parse(json['amount'].toString()),
      count: json['count'] ?? 1,
      type: json['type'],
      gameName: json['game_name'] ?? '',
      gameTime: json['game_time'] ?? '',
      username: json['user_username'], // Updated to match view's custom dict
      createdAt: DateTime.parse(json['created_at']),
      totalAmount:
          double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      commission: double.tryParse(json['commission']?.toString() ?? '0') ?? 0.0,
      netAmount: double.tryParse(json['net_amount']?.toString() ?? '0') ?? 0.0,
      gameCanEditDelete: json['game_can_edit_delete'],
      gameEditDeleteLimitTime: json['game_edit_delete_limit_time'],
    );
  }
}
