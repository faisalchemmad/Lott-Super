class GameModel {
  final int id;
  final String name;
  final String time;
  final String startTime;
  final String endTime;
  final String color;

  // Global Count Limits
  final int globalCountA;
  final int globalCountB;
  final int globalCountC;
  final int globalCountAb;
  final int globalCountBc;
  final int globalCountAc;
  final int globalCountSuper;
  final int globalCountBox;
  final bool canEditDelete;
  final String editDeleteLimitTime;

  GameModel({
    required this.id,
    required this.name,
    required this.time,
    this.startTime = '00:00:00',
    this.endTime = '23:59:59',
    this.color = '#2C3E50',
    this.globalCountA = 0,
    this.globalCountB = 0,
    this.globalCountC = 0,
    this.globalCountAb = 0,
    this.globalCountBc = 0,
    this.globalCountAc = 0,
    this.globalCountSuper = 0,
    this.globalCountBox = 0,
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
      globalCountA: json['global_count_a'] ?? 0,
      globalCountB: json['global_count_b'] ?? 0,
      globalCountC: json['global_count_c'] ?? 0,
      globalCountAb: json['global_count_ab'] ?? 0,
      globalCountBc: json['global_count_bc'] ?? 0,
      globalCountAc: json['global_count_ac'] ?? 0,
      globalCountSuper: json['global_count_super'] ?? 0,
      globalCountBox: json['global_count_box'] ?? 0,
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
      'can_edit_delete': canEditDelete,
      'edit_delete_limit_time': editDeleteLimitTime,
    };
  }
}
