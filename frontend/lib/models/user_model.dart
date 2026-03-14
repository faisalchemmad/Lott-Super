class UserModel {
  final int id;
  final String username;
  final String role;
  final double weeklyCreditLimit;
  final double remainingCredit;
  final String dateJoined;
  final int? parent;
  final bool isDefault;
  final List<int> allowedGames;

  // Count Limits
  final int countA;
  final int countB;
  final int countC;
  final int countAB;
  final int countBC;
  final int countAC;
  final int countSuper;
  final int countBox;

  // Price Defaults (per unit)
  final double priceAbc;
  final double priceAbBcAc;
  final double priceSuper;
  final double priceBox;

  // Prize and Commission Settings
  final double prizeSuper1;
  final double commSuper1;
  final double prizeSuper2;
  final double commSuper2;
  final double prizeSuper3;
  final double commSuper3;
  final double prizeSuper4;
  final double commSuper4;
  final double prizeSuper5;
  final double commSuper5;

  final double prize6th;
  final double comm6th;

  final double prizeAbBcAc1;
  final double commAbBcAc1;

  final double prizeAbc1;
  final double commAbc1;

  final double prizeBox3d1;
  final double commBox3d1;
  final double prizeBox3d2;
  final double commBox3d2;

  final double prizeBox2s1;
  final double commBox2s1;
  final double prizeBox2s2;
  final double commBox2s2;

  final double prizeBox3s1;
  final double commBox3s1;

  // Sales Commission Settings
  final double salesCommSuper;
  final double salesCommAbc;
  final double salesCommAbBcAc;
  final double salesCommBox;
  final bool isBlocked;

  UserModel({
    required this.id,
    required this.username,
    required this.role,
    this.weeklyCreditLimit = 0,
    this.remainingCredit = 0,
    this.dateJoined = '',
    this.countA = 0,
    this.countB = 0,
    this.countC = 0,
    this.countAB = 0,
    this.countBC = 0,
    this.countAC = 0,
    this.countSuper = 0,
    this.countBox = 0,
    this.priceAbc = 12.0,
    this.priceAbBcAc = 10.0,
    this.priceSuper = 10.0,
    this.priceBox = 10.0,
    this.prizeSuper1 = 5000,
    this.commSuper1 = 400,
    this.prizeSuper2 = 500,
    this.commSuper2 = 50,
    this.prizeSuper3 = 250,
    this.commSuper3 = 20,
    this.prizeSuper4 = 100,
    this.commSuper4 = 20,
    this.prizeSuper5 = 50,
    this.commSuper5 = 20,
    this.prize6th = 20,
    this.comm6th = 10,
    this.prizeAbBcAc1 = 700,
    this.commAbBcAc1 = 30,
    this.prizeAbc1 = 100,
    this.commAbc1 = 0,
    this.prizeBox3d1 = 3000,
    this.commBox3d1 = 300,
    this.prizeBox3d2 = 800,
    this.commBox3d2 = 30,
    this.prizeBox2s1 = 3800,
    this.commBox2s1 = 330,
    this.prizeBox2s2 = 1600,
    this.commBox2s2 = 60,
    this.prizeBox3s1 = 7000,
    this.commBox3s1 = 450,
    this.salesCommSuper = 0.0,
    this.salesCommAbc = 0.0,
    this.salesCommAbBcAc = 0.0,
    this.salesCommBox = 0.0,
    this.isBlocked = false,
    this.isDefault = false,
    this.parent,
    this.allowedGames = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      role: json['role'],
      weeklyCreditLimit:
          double.parse(json['weekly_credit_limit']?.toString() ?? '0.0'),
      remainingCredit:
          double.parse(json['remaining_credit']?.toString() ?? '0.0'),
      dateJoined: json['date_joined'] ?? '',
      countA: json['count_a'] ?? 0,
      countB: json['count_b'] ?? 0,
      countC: json['count_c'] ?? 0,
      countAB: json['count_ab'] ?? 0,
      countBC: json['count_bc'] ?? 0,
      countAC: json['count_ac'] ?? 0,
      countSuper: json['count_super'] ?? 0,
      countBox: json['count_box'] ?? 0,
      priceAbc: double.parse(json['price_abc']?.toString() ?? '12.0'),
      priceAbBcAc: double.parse(json['price_ab_bc_ac']?.toString() ?? '10.0'),
      priceSuper: double.parse(json['price_super']?.toString() ?? '10.0'),
      priceBox: double.parse(json['price_box']?.toString() ?? '10.0'),
      prizeSuper1: double.parse(json['prize_super_1']?.toString() ?? '5000'),
      commSuper1: double.parse(json['comm_super_1']?.toString() ?? '400'),
      prizeSuper2: double.parse(json['prize_super_2']?.toString() ?? '500'),
      commSuper2: double.parse(json['comm_super_2']?.toString() ?? '50'),
      prizeSuper3: double.parse(json['prize_super_3']?.toString() ?? '250'),
      commSuper3: double.parse(json['comm_super_3']?.toString() ?? '20'),
      prizeSuper4: double.parse(json['prize_super_4']?.toString() ?? '100'),
      commSuper4: double.parse(json['comm_super_4']?.toString() ?? '20'),
      prizeSuper5: double.parse(json['prize_super_5']?.toString() ?? '50'),
      commSuper5: double.parse(json['comm_super_5']?.toString() ?? '20'),
      prize6th: double.parse(json['prize_6th']?.toString() ?? '20'),
      comm6th: double.parse(json['comm_6th']?.toString() ?? '10'),
      prizeAbBcAc1: double.parse(json['prize_ab_bc_ac_1']?.toString() ?? '700'),
      commAbBcAc1: double.parse(json['comm_ab_bc_ac_1']?.toString() ?? '30'),
      prizeAbc1: double.parse(json['prize_abc_1']?.toString() ?? '100'),
      commAbc1: double.parse(json['comm_abc_1']?.toString() ?? '0'),
      prizeBox3d1: double.parse(json['prize_box_3d_1']?.toString() ?? '3000'),
      commBox3d1: double.parse(json['comm_box_3d_1']?.toString() ?? '300'),
      prizeBox3d2: double.parse(json['prize_box_3d_2']?.toString() ?? '800'),
      commBox3d2: double.parse(json['comm_box_3d_2']?.toString() ?? '30'),
      prizeBox2s1: double.parse(json['prize_box_2s_1']?.toString() ?? '3800'),
      commBox2s1: double.parse(json['comm_box_2s_1']?.toString() ?? '330'),
      prizeBox2s2: double.parse(json['prize_box_2s_2']?.toString() ?? '1600'),
      commBox2s2: double.parse(json['comm_box_2s_2']?.toString() ?? '60'),
      prizeBox3s1: double.parse(json['prize_box_3s_1']?.toString() ?? '7000'),
      commBox3s1: double.parse(json['comm_box_3s_1']?.toString() ?? '450'),
      salesCommSuper:
          double.parse(json['sales_comm_super']?.toString() ?? '0.0'),
      salesCommAbc: double.parse(json['sales_comm_abc']?.toString() ?? '0.0'),
      salesCommAbBcAc:
          double.parse(json['sales_comm_ab_bc_ac']?.toString() ?? '0.0'),
      salesCommBox: double.parse(json['sales_comm_box']?.toString() ?? '0.0'),
      isBlocked: json['is_blocked'] ?? false,
      isDefault: json['is_default'] ?? false,
      parent: json['parent'],
      allowedGames: (json['allowed_games'] as List?)?.map((e) => e as int).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'parent': parent,
      'weekly_credit_limit': weeklyCreditLimit,
      'remaining_credit': remainingCredit,
      'date_joined': dateJoined,
      'count_a': countA,
      'count_b': countB,
      'count_c': countC,
      'count_ab': countAB,
      'count_bc': countBC,
      'count_ac': countAC,
      'count_super': countSuper,
      'count_box': countBox,
      'price_abc': priceAbc,
      'price_ab_bc_ac': priceAbBcAc,
      'price_super': priceSuper,
      'price_box': priceBox,
      'prize_super_1': prizeSuper1,
      'comm_super_1': commSuper1,
      'prize_super_2': prizeSuper2,
      'comm_super_2': commSuper2,
      'prize_super_3': prizeSuper3,
      'comm_super_3': commSuper3,
      'prize_super_4': prizeSuper4,
      'comm_super_4': commSuper4,
      'prize_super_5': prizeSuper5,
      'comm_super_5': commSuper5,
      'prize_6th': prize6th,
      'comm_6th': comm6th,
      'prize_ab_bc_ac_1': prizeAbBcAc1,
      'comm_ab_bc_ac_1': commAbBcAc1,
      'prize_abc_1': prizeAbc1,
      'comm_abc_1': commAbc1,
      'prize_box_3d_1': prizeBox3d1,
      'comm_box_3d_1': commBox3d1,
      'prize_box_3d_2': prizeBox3d2,
      'comm_box_3d_2': commBox3d2,
      'prize_box_2s_1': prizeBox2s1,
      'comm_box_2s_1': commBox2s1,
      'prize_box_2s_2': prizeBox2s2,
      'comm_box_2s_2': commBox2s2,
      'prize_box_3s_1': prizeBox3s1,
      'comm_box_3s_1': commBox3s1,
      'sales_comm_super': salesCommSuper,
      'sales_comm_abc': salesCommAbc,
      'sales_comm_ab_bc_ac': salesCommAbBcAc,
      'sales_comm_box': salesCommBox,
      'is_blocked': isBlocked,
      'is_default': isDefault,
      'allowed_games': allowedGames,
    };
  }
}
