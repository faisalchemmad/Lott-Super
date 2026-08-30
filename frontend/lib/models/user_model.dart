class UserModel {
  final int id;
  final String username;
  final String role;
  final double weeklyCreditLimit;
  final double remainingCredit;
  final String dateJoined;
  final int? parent;
  final bool isDefault;
  final bool canForward;
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

  // TN Count Limits
  final int tnCountA;
  final int tnCountB;
  final int tnCountC;
  final int tnCountAB;
  final int tnCountBC;
  final int tnCountAC;
  final int tnCount3d10;
  final int tnCount3d25;
  final int tnCount3d30;
  final int tnCount3d60;
  final int tnCount4d110;
  final int tnCount4d55;
  final int tnCount4d20;

  // Price Defaults (per unit)
  final double priceAbc;
  final double priceAbBcAc;
  final double priceSuper;
  final double priceBox;

  // TN Price Defaults (per unit)
  final double tnPriceAbc;
  final double tnPriceAbBcAc;
  final double tnPrice3d10;
  final double tnPrice3d25;
  final double tnPrice3d30;
  final double tnPrice3d60;
  final double tnPrice4d110;
  final double tnPrice4d55;
  final double tnPrice4d20;

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

  // TN Prize Settings
  final double tnPrizeAbc;
  final double tnPrizeAbBcAc;
  final double tnPrize3d10;
  final double tnPrize3d10Bc;
  final double tnPrize3d25;
  final double tnPrize3d25Bc;
  final double tnPrize3d30;
  final double tnPrize3d30Bc;
  final double tnPrize3d30C;
  final double tnPrize3d60;
  final double tnPrize3d60Bc;
  final double tnPrize3d60C;
  final double tnPrize4d110_1;
  final double tnPrize4d110_2;
  final double tnPrize4d110_3;
  final double tnPrize4d110_4;
  final double tnPrize4d55_1;
  final double tnPrize4d55_2;
  final double tnPrize4d55_3;
  final double tnPrize4d55_4;
  final double tnPrize4d20_1;
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

  // TN Sales Commission Settings
  final double tnSalesCommAbc;
  final double tnSalesCommAbBcAc;
  final double tnSalesComm3d10;
  final double tnSalesComm3d25;
  final double tnSalesComm3d30;
  final double tnSalesComm3d60;
  final double tnSalesComm4d110;
  final double tnSalesComm4d55;
  final double tnSalesComm4d20;
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
    this.tnCountA = 0,
    this.tnCountB = 0,
    this.tnCountC = 0,
    this.tnCountAB = 0,
    this.tnCountBC = 0,
    this.tnCountAC = 0,
    this.tnCount3d10 = 0,
    this.tnCount3d25 = 0,
    this.tnCount3d30 = 0,
    this.tnCount3d60 = 0,
    this.tnCount4d110 = 0,
    this.tnCount4d55 = 0,
    this.tnCount4d20 = 0,
    this.priceAbc = 12.0,
    this.priceAbBcAc = 10.0,
    this.priceSuper = 10.0,
    this.priceBox = 10.0,
    this.tnPriceAbc = 12.0,
    this.tnPriceAbBcAc = 10.0,
    this.tnPrice3d10 = 10.0,
    this.tnPrice3d25 = 25.0,
    this.tnPrice3d30 = 30.0,
    this.tnPrice3d60 = 60.0,
    this.tnPrice4d110 = 110.0,
    this.tnPrice4d55 = 55.0,
    this.tnPrice4d20 = 20.0,
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
    this.tnPrizeAbc = 1000.0,
    this.tnPrizeAbBcAc = 1000.0,
    this.tnPrize3d10 = 5000.0,
    this.tnPrize3d10Bc = 100.0,
    this.tnPrize3d25 = 10000.0,
    this.tnPrize3d25Bc = 1000.0,
    this.tnPrize3d30 = 15000.0,
    this.tnPrize3d30Bc = 500.0,
    this.tnPrize3d30C = 50.0,
    this.tnPrize3d60 = 30000.0,
    this.tnPrize3d60Bc = 1000.0,
    this.tnPrize3d60C = 100.0,
    this.tnPrize4d110_1 = 450000.0,
    this.tnPrize4d110_2 = 10000.0,
    this.tnPrize4d110_3 = 1000.0,
    this.tnPrize4d110_4 = 100.0,
    this.tnPrize4d55_1 = 225000.0,
    this.tnPrize4d55_2 = 5000.0,
    this.tnPrize4d55_3 = 500.0,
    this.tnPrize4d55_4 = 50.0,
    this.tnPrize4d20_1 = 100000.0,
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
    this.tnSalesCommAbc = 0.0,
    this.tnSalesCommAbBcAc = 0.0,
    this.tnSalesComm3d10 = 0.0,
    this.tnSalesComm3d25 = 0.0,
    this.tnSalesComm3d30 = 0.0,
    this.tnSalesComm3d60 = 0.0,
    this.tnSalesComm4d110 = 0.0,
    this.tnSalesComm4d55 = 0.0,
    this.tnSalesComm4d20 = 0.0,
    this.isBlocked = false,
    this.isDefault = false,
    this.canForward = false,
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
      tnCountA: json['tn_count_a'] ?? 0,
      tnCountB: json['tn_count_b'] ?? 0,
      tnCountC: json['tn_count_c'] ?? 0,
      tnCountAB: json['tn_count_ab'] ?? 0,
      tnCountBC: json['tn_count_bc'] ?? 0,
      tnCountAC: json['tn_count_ac'] ?? 0,
      tnCount3d10: json['tn_count_3d_10'] ?? 0,
      tnCount3d25: json['tn_count_3d_25'] ?? 0,
      tnCount3d30: json['tn_count_3d_30'] ?? 0,
      tnCount3d60: json['tn_count_3d_60'] ?? 0,
      tnCount4d110: json['tn_count_4d_110'] ?? 0,
      tnCount4d55: json['tn_count_4d_55'] ?? 0,
      tnCount4d20: json['tn_count_4d_20'] ?? 0,
      priceAbc: double.parse(json['price_abc']?.toString() ?? '12.0'),
      priceAbBcAc: double.parse(json['price_ab_bc_ac']?.toString() ?? '10.0'),
      priceSuper: double.parse(json['price_super']?.toString() ?? '10.0'),
      priceBox: double.parse(json['price_box']?.toString() ?? '10.0'),
      tnPriceAbc: double.parse(json['tn_price_abc']?.toString() ?? '12.0'),
      tnPriceAbBcAc:
          double.parse(json['tn_price_ab_bc_ac']?.toString() ?? '10.0'),
      tnPrice3d10: double.parse(json['tn_price_3d_10']?.toString() ?? '10.0'),
      tnPrice3d25: double.parse(json['tn_price_3d_25']?.toString() ?? '25.0'),
      tnPrice3d30: double.parse(json['tn_price_3d_30']?.toString() ?? '30.0'),
      tnPrice3d60: double.parse(json['tn_price_3d_60']?.toString() ?? '60.0'),
      tnPrice4d110:
          double.parse(json['tn_price_4d_110']?.toString() ?? '110.0'),
      tnPrice4d55: double.parse(json['tn_price_4d_55']?.toString() ?? '55.0'),
      tnPrice4d20: double.parse(json['tn_price_4d_20']?.toString() ?? '20.0'),
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
      tnPrizeAbc: double.parse(json['tn_prize_abc']?.toString() ?? '1000.0'),
      tnPrizeAbBcAc:
          double.parse(json['tn_prize_ab_bc_ac']?.toString() ?? '1000.0'),
      tnPrize3d10: double.parse(json['tn_prize_3d_10']?.toString() ?? '5000.0'),
      tnPrize3d10Bc:
          double.parse(json['tn_prize_3d_10_bc']?.toString() ?? '100.0'),
      tnPrize3d25:
          double.parse(json['tn_prize_3d_25']?.toString() ?? '10000.0'),
      tnPrize3d25Bc:
          double.parse(json['tn_prize_3d_25_bc']?.toString() ?? '1000.0'),
      tnPrize3d30:
          double.parse(json['tn_prize_3d_30']?.toString() ?? '15000.0'),
      tnPrize3d30Bc:
          double.parse(json['tn_prize_3d_30_bc']?.toString() ?? '500.0'),
      tnPrize3d30C:
          double.parse(json['tn_prize_3d_30_c']?.toString() ?? '50.0'),
      tnPrize3d60:
          double.parse(json['tn_prize_3d_60']?.toString() ?? '30000.0'),
      tnPrize3d60Bc:
          double.parse(json['tn_prize_3d_60_bc']?.toString() ?? '1000.0'),
      tnPrize3d60C:
          double.parse(json['tn_prize_3d_60_c']?.toString() ?? '100.0'),
      tnPrize4d110_1:
          double.parse(json['tn_prize_4d_110_1']?.toString() ?? '450000.0'),
      tnPrize4d110_2:
          double.parse(json['tn_prize_4d_110_2']?.toString() ?? '10000.0'),
      tnPrize4d110_3:
          double.parse(json['tn_prize_4d_110_3']?.toString() ?? '1000.0'),
      tnPrize4d110_4:
          double.parse(json['tn_prize_4d_110_4']?.toString() ?? '100.0'),
      tnPrize4d55_1:
          double.parse(json['tn_prize_4d_55_1']?.toString() ?? '225000.0'),
      tnPrize4d55_2:
          double.parse(json['tn_prize_4d_55_2']?.toString() ?? '5000.0'),
      tnPrize4d55_3:
          double.parse(json['tn_prize_4d_55_3']?.toString() ?? '500.0'),
      tnPrize4d55_4:
          double.parse(json['tn_prize_4d_55_4']?.toString() ?? '50.0'),
      tnPrize4d20_1:
          double.parse(json['tn_prize_4d_20_1']?.toString() ?? '100000.0'),
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
      tnSalesCommAbc:
          double.parse(json['tn_sales_comm_abc']?.toString() ?? '0.0'),
      tnSalesCommAbBcAc:
          double.parse(json['tn_sales_comm_ab_bc_ac']?.toString() ?? '0.0'),
      tnSalesComm3d10:
          double.parse(json['tn_sales_comm_3d_10']?.toString() ?? '0.0'),
      tnSalesComm3d25:
          double.parse(json['tn_sales_comm_3d_25']?.toString() ?? '0.0'),
      tnSalesComm3d30:
          double.parse(json['tn_sales_comm_3d_30']?.toString() ?? '0.0'),
      tnSalesComm3d60:
          double.parse(json['tn_sales_comm_3d_60']?.toString() ?? '0.0'),
      tnSalesComm4d110:
          double.parse(json['tn_sales_comm_4d_110']?.toString() ?? '0.0'),
      tnSalesComm4d55:
          double.parse(json['tn_sales_comm_4d_55']?.toString() ?? '0.0'),
      tnSalesComm4d20:
          double.parse(json['tn_sales_comm_4d_20']?.toString() ?? '0.0'),
      isBlocked: json['is_blocked'] ?? false,
      isDefault: json['is_default'] ?? false,
      canForward: json['can_forward'] ?? false,
      parent: json['parent'],
      allowedGames:
          (json['allowed_games'] as List?)?.map((e) => e as int).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'parent': parent,
      'can_forward': canForward,
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
      'tn_count_a': tnCountA,
      'tn_count_b': tnCountB,
      'tn_count_c': tnCountC,
      'tn_count_ab': tnCountAB,
      'tn_count_bc': tnCountBC,
      'tn_count_ac': tnCountAC,
      'tn_count_3d_10': tnCount3d10,
      'tn_count_3d_25': tnCount3d25,
      'tn_count_3d_30': tnCount3d30,
      'tn_count_3d_60': tnCount3d60,
      'tn_count_4d_110': tnCount4d110,
      'tn_count_4d_55': tnCount4d55,
      'tn_count_4d_20': tnCount4d20,
      'price_abc': priceAbc,
      'price_ab_bc_ac': priceAbBcAc,
      'price_super': priceSuper,
      'price_box': priceBox,
      'tn_price_abc': tnPriceAbc,
      'tn_price_ab_bc_ac': tnPriceAbBcAc,
      'tn_price_3d_10': tnPrice3d10,
      'tn_price_3d_25': tnPrice3d25,
      'tn_price_3d_30': tnPrice3d30,
      'tn_price_3d_60': tnPrice3d60,
      'tn_price_4d_110': tnPrice4d110,
      'tn_price_4d_55': tnPrice4d55,
      'tn_price_4d_20': tnPrice4d20,
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
      'tn_prize_abc': tnPrizeAbc,
      'tn_prize_ab_bc_ac': tnPrizeAbBcAc,
      'tn_prize_3d_10': tnPrize3d10,
      'tn_prize_3d_10_bc': tnPrize3d10Bc,
      'tn_prize_3d_25': tnPrize3d25,
      'tn_prize_3d_25_bc': tnPrize3d25Bc,
      'tn_prize_3d_30': tnPrize3d30,
      'tn_prize_3d_30_bc': tnPrize3d30Bc,
      'tn_prize_3d_30_c': tnPrize3d30C,
      'tn_prize_3d_60': tnPrize3d60,
      'tn_prize_3d_60_bc': tnPrize3d60Bc,
      'tn_prize_3d_60_c': tnPrize3d60C,
      'tn_prize_4d_110_1': tnPrize4d110_1,
      'tn_prize_4d_110_2': tnPrize4d110_2,
      'tn_prize_4d_110_3': tnPrize4d110_3,
      'tn_prize_4d_110_4': tnPrize4d110_4,
      'tn_prize_4d_55_1': tnPrize4d55_1,
      'tn_prize_4d_55_2': tnPrize4d55_2,
      'tn_prize_4d_55_3': tnPrize4d55_3,
      'tn_prize_4d_55_4': tnPrize4d55_4,
      'tn_prize_4d_20_1': tnPrize4d20_1,
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
      'tn_sales_comm_abc': tnSalesCommAbc,
      'tn_sales_comm_ab_bc_ac': tnSalesCommAbBcAc,
      'tn_sales_comm_3d_10': tnSalesComm3d10,
      'tn_sales_comm_3d_25': tnSalesComm3d25,
      'tn_sales_comm_3d_30': tnSalesComm3d30,
      'tn_sales_comm_3d_60': tnSalesComm3d60,
      'tn_sales_comm_4d_110': tnSalesComm4d110,
      'tn_sales_comm_4d_55': tnSalesComm4d55,
      'tn_sales_comm_4d_20': tnSalesComm4d20,
      'is_blocked': isBlocked,
      'is_default': isDefault,
      'allowed_games': allowedGames,
    };
  }
}
