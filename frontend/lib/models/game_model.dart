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
  final int rushTimeMinutes;
  final int rushTimeMaxCount;

  // KL Rush Type Counts
  final int rushCountA;
  final int rushCountB;
  final int rushCountC;
  final int rushCountAb;
  final int rushCountBc;
  final int rushCountAc;
  final int rushCountSuper;
  final int rushCountBox;

  // TN Rush Type Counts
  final int rushTnCountA;
  final int rushTnCountB;
  final int rushTnCountC;
  final int rushTnCountAb;
  final int rushTnCountBc;
  final int rushTnCountAc;
  final int rushTnCount3d10;
  final int rushTnCount3d25;
  final int rushTnCount3d30;
  final int rushTnCount3d60;
  final int rushTnCount4d110;
  final int rushTnCount4d55;
  final int rushTnCount4d20;

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
    this.rushTimeMinutes = 0,
    this.rushTimeMaxCount = 0,
    this.rushCountA = 0,
    this.rushCountB = 0,
    this.rushCountC = 0,
    this.rushCountAb = 0,
    this.rushCountBc = 0,
    this.rushCountAc = 0,
    this.rushCountSuper = 0,
    this.rushCountBox = 0,
    this.rushTnCountA = 0,
    this.rushTnCountB = 0,
    this.rushTnCountC = 0,
    this.rushTnCountAb = 0,
    this.rushTnCountBc = 0,
    this.rushTnCountAc = 0,
    this.rushTnCount3d10 = 0,
    this.rushTnCount3d25 = 0,
    this.rushTnCount3d30 = 0,
    this.rushTnCount3d60 = 0,
    this.rushTnCount4d110 = 0,
    this.rushTnCount4d55 = 0,
    this.rushTnCount4d20 = 0,
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
      rushTimeMinutes: json['rush_time_minutes'] ?? 0,
      rushTimeMaxCount: json['rush_time_max_count'] ?? 0,
      rushCountA: json['rush_count_a'] ?? 0,
      rushCountB: json['rush_count_b'] ?? 0,
      rushCountC: json['rush_count_c'] ?? 0,
      rushCountAb: json['rush_count_ab'] ?? 0,
      rushCountBc: json['rush_count_bc'] ?? 0,
      rushCountAc: json['rush_count_ac'] ?? 0,
      rushCountSuper: json['rush_count_super'] ?? 0,
      rushCountBox: json['rush_count_box'] ?? 0,
      rushTnCountA: json['rush_tn_count_a'] ?? 0,
      rushTnCountB: json['rush_tn_count_b'] ?? 0,
      rushTnCountC: json['rush_tn_count_c'] ?? 0,
      rushTnCountAb: json['rush_tn_count_ab'] ?? 0,
      rushTnCountBc: json['rush_tn_count_bc'] ?? 0,
      rushTnCountAc: json['rush_tn_count_ac'] ?? 0,
      rushTnCount3d10: json['rush_tn_count_3d_10'] ?? 0,
      rushTnCount3d25: json['rush_tn_count_3d_25'] ?? 0,
      rushTnCount3d30: json['rush_tn_count_3d_30'] ?? 0,
      rushTnCount3d60: json['rush_tn_count_3d_60'] ?? 0,
      rushTnCount4d110: json['rush_tn_count_4d_110'] ?? 0,
      rushTnCount4d55: json['rush_tn_count_4d_55'] ?? 0,
      rushTnCount4d20: json['rush_tn_count_4d_20'] ?? 0,
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
      'options_bg_color': optionsBgColor,
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
      'rush_time_minutes': rushTimeMinutes,
      'rush_time_max_count': rushTimeMaxCount,
      'rush_count_a': rushCountA,
      'rush_count_b': rushCountB,
      'rush_count_c': rushCountC,
      'rush_count_ab': rushCountAb,
      'rush_count_bc': rushCountBc,
      'rush_count_ac': rushCountAc,
      'rush_count_super': rushCountSuper,
      'rush_count_box': rushCountBox,
      'rush_tn_count_a': rushTnCountA,
      'rush_tn_count_b': rushTnCountB,
      'rush_tn_count_c': rushTnCountC,
      'rush_tn_count_ab': rushTnCountAb,
      'rush_tn_count_bc': rushTnCountBc,
      'rush_tn_count_ac': rushTnCountAc,
      'rush_tn_count_3d_10': rushTnCount3d10,
      'rush_tn_count_3d_25': rushTnCount3d25,
      'rush_tn_count_3d_30': rushTnCount3d30,
      'rush_tn_count_3d_60': rushTnCount3d60,
      'rush_tn_count_4d_110': rushTnCount4d110,
      'rush_tn_count_4d_55': rushTnCount4d55,
      'rush_tn_count_4d_20': rushTnCount4d20,
    };
  }
}
