import sys

p = r'd:\Gemini\Android\Lott_super\frontend\lib\models\user_model.dart'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()

props_to_add = """  // TN Prize Settings
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
"""

constructor_args = """    this.tnPrizeAbc = 1000.0,
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
"""

fromjson_args = """      tnPrizeAbc: (json['tn_prize_abc'] ?? 1000.0).toDouble(),
      tnPrizeAbBcAc: (json['tn_prize_ab_bc_ac'] ?? 1000.0).toDouble(),
      tnPrize3d10: (json['tn_prize_3d_10'] ?? 5000.0).toDouble(),
      tnPrize3d10Bc: (json['tn_prize_3d_10_bc'] ?? 100.0).toDouble(),
      tnPrize3d25: (json['tn_prize_3d_25'] ?? 10000.0).toDouble(),
      tnPrize3d25Bc: (json['tn_prize_3d_25_bc'] ?? 1000.0).toDouble(),
      tnPrize3d30: (json['tn_prize_3d_30'] ?? 15000.0).toDouble(),
      tnPrize3d30Bc: (json['tn_prize_3d_30_bc'] ?? 500.0).toDouble(),
      tnPrize3d30C: (json['tn_prize_3d_30_c'] ?? 50.0).toDouble(),
      tnPrize3d60: (json['tn_prize_3d_60'] ?? 30000.0).toDouble(),
      tnPrize3d60Bc: (json['tn_prize_3d_60_bc'] ?? 1000.0).toDouble(),
      tnPrize3d60C: (json['tn_prize_3d_60_c'] ?? 100.0).toDouble(),
      tnPrize4d110_1: (json['tn_prize_4d_110_1'] ?? 450000.0).toDouble(),
      tnPrize4d110_2: (json['tn_prize_4d_110_2'] ?? 10000.0).toDouble(),
      tnPrize4d110_3: (json['tn_prize_4d_110_3'] ?? 1000.0).toDouble(),
      tnPrize4d110_4: (json['tn_prize_4d_110_4'] ?? 100.0).toDouble(),
      tnPrize4d55_1: (json['tn_prize_4d_55_1'] ?? 225000.0).toDouble(),
      tnPrize4d55_2: (json['tn_prize_4d_55_2'] ?? 5000.0).toDouble(),
      tnPrize4d55_3: (json['tn_prize_4d_55_3'] ?? 500.0).toDouble(),
      tnPrize4d55_4: (json['tn_prize_4d_55_4'] ?? 50.0).toDouble(),
      tnPrize4d20_1: (json['tn_prize_4d_20_1'] ?? 100000.0).toDouble(),
"""

tojson_args = """      'tn_prize_abc': tnPrizeAbc,
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
"""

if 'tnPrizeAbc' not in c:
    # insert props
    idx = c.find('final double prize6th;')
    c = c[:idx] + props_to_add + c[idx:]
    
    # insert constr args
    idx = c.find('this.prize6th = 20.0,')
    c = c[:idx] + constructor_args + c[idx:]
    
    # insert fromjson args
    idx = c.find("prize6th: (json['prize_6th'] ?? 20.0).toDouble(),")
    c = c[:idx] + fromjson_args + c[idx:]
    
    # insert tojson args
    idx = c.find("'prize_6th': prize6th,")
    c = c[:idx] + tojson_args + c[idx:]

    with open(p, 'w', encoding='utf-8') as f:
        f.write(c)
    print("user_model.dart patched!")
else:
    print("already patched!")
