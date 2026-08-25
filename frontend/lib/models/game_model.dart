class GameModel {
  final int id;
  final String name;
  final String time;
  final String startTime;
  final String endTime;
  final String color;
  final String optionsBgColor;

  // Global Count Limits (KL)
  final int globalCountA;
  final int globalCountB;
  final int globalCountC;
  final int globalCountAb;
  final int globalCountBc;
  final int globalCountAc;
  final int globalCountSuper;
  final int globalCountBox;

  // Global Count Limits (TN)
  final int globalTnCountA;
  final int globalTnCountB;
  final int globalTnCountC;
  final int globalTnCountAb;
  final int globalTnCountBc;
  final int globalTnCountAc;
  final int globalTnCount3d10;
  final int globalTnCount3d25;
  final int globalTnCount3d30;
  final int globalTnCount3d60;
  final int globalTnCount4d110;
  final int globalTnCount4d55;
  final int globalTnCount4d20;

  final bool canEditDelete;
  final String editDeleteLimitTime;

  GameModel({
    required this.id,
    required this.name,
    required this.time,
    this.startTime = '00:00:00',
    this.endTime = '23:59:59',
    this.color = '#2C3E50',
    this.optionsBgColor = '#FFFFFF',
    this.globalCountA = 0,
    this.globalCountB = 0,
    this.globalCountC = 0,
    this.globalCountAb = 0,
    this.globalCountBc = 0,
    this.globalCountAc = 0,
    this.globalCountSuper = 0,
    this.globalCountBox = 0,
    this.globalTnCountA = 0,
    this.globalTnCountB = 0,
    this.globalTnCountC = 0,
    this.globalTnCountAb = 0,
    this.globalTnCountBc = 0,
    this.globalTnCountAc = 0,
    this.globalTnCount3d10 = 0,
    this.globalTnCount3d25 = 0,
    this.globalTnCount3d30 = 0,
    this.globalTnCount3d60 = 0,
    this.globalTnCount4d110 = 0,
    this.globalTnCount4d55 = 0,
    this.globalTnCount4d20 = 0,
    this.canEditDelete = true,
    this.editDeleteLimitTime = '23:59:59',
  });

  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      id: json['id'],
      name: json['name'],
      time: json['time'],
      startTime: json['start_time'] ?? '00:00:00',
      endTime: json['end_time'] ?? '23:59:59',
      color: json['color'] ?? '#2C3E50',
      optionsBgColor: json['options_bg_color'] ?? '#FFFFFF',
      globalCountA: json['global_count_a'] ?? 0,
      globalCountB: json['global_count_b'] ?? 0,
      globalCountC: json['global_count_c'] ?? 0,
      globalCountAb: json['global_count_ab'] ?? 0,
      globalCountBc: json['global_count_bc'] ?? 0,
      globalCountAc: json['global_count_ac'] ?? 0,
      globalCountSuper: json['global_count_super'] ?? 0,
      globalCountBox: json['global_count_box'] ?? 0,
      globalTnCountA: json['global_tn_count_a'] ?? 0,
      globalTnCountB: json['global_tn_count_b'] ?? 0,
      globalTnCountC: json['global_tn_count_c'] ?? 0,
      globalTnCountAb: json['global_tn_count_ab'] ?? 0,
      globalTnCountBc: json['global_tn_count_bc'] ?? 0,
      globalTnCountAc: json['global_tn_count_ac'] ?? 0,
      globalTnCount3d10: json['global_tn_count_3d_10'] ?? 0,
      globalTnCount3d25: json['global_tn_count_3d_25'] ?? 0,
      globalTnCount3d30: json['global_tn_count_3d_30'] ?? 0,
      globalTnCount3d60: json['global_tn_count_3d_60'] ?? 0,
      globalTnCount4d110: json['global_tn_count_4d_110'] ?? 0,
      globalTnCount4d55: json['global_tn_count_4d_55'] ?? 0,
      globalTnCount4d20: json['global_tn_count_4d_20'] ?? 0,
      canEditDelete: json['can_edit_delete'] ?? true,
      editDeleteLimitTime: json['edit_delete_limit_time'] ?? '23:59:59',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'time': time,
      'start_time': startTime,
      'end_time': endTime,
      'color': color,
      'global_count_a': globalCountA,
      'global_count_b': globalCountB,
      'global_count_c': globalCountC,
      'global_count_ab': globalCountAb,
      'global_count_bc': globalCountBc,
      'global_count_ac': globalCountAc,
      'global_count_super': globalCountSuper,
      'global_count_box': globalCountBox,
      'global_tn_count_a': globalTnCountA,
      'global_tn_count_b': globalTnCountB,
      'global_tn_count_c': globalTnCountC,
      'global_tn_count_ab': globalTnCountAb,
      'global_tn_count_bc': globalTnCountBc,
      'global_tn_count_ac': globalTnCountAc,
      'global_tn_count_3d_10': globalTnCount3d10,
      'global_tn_count_3d_25': globalTnCount3d25,
      'global_tn_count_3d_30': globalTnCount3d30,
      'global_tn_count_3d_60': globalTnCount3d60,
      'global_tn_count_4d_110': globalTnCount4d110,
      'global_tn_count_4d_55': globalTnCount4d55,
      'global_tn_count_4d_20': globalTnCount4d20,
      'can_edit_delete': canEditDelete,
      'edit_delete_limit_time': editDeleteLimitTime,
    };
  }
}
