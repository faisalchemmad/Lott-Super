import sys

p = r'd:\Gemini\Android\Lott_super\backend\core\serializers.py'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()

fields_to_add = """            'tn_prize_abc', 'tn_prize_ab_bc_ac', 
            'tn_prize_3d_10', 'tn_prize_3d_10_bc', 'tn_prize_3d_25', 'tn_prize_3d_25_bc',
            'tn_prize_3d_30', 'tn_prize_3d_30_bc', 'tn_prize_3d_30_c',
            'tn_prize_3d_60', 'tn_prize_3d_60_bc', 'tn_prize_3d_60_c',
            'tn_prize_4d_110_1', 'tn_prize_4d_110_2', 'tn_prize_4d_110_3', 'tn_prize_4d_110_4',
            'tn_prize_4d_55_1', 'tn_prize_4d_55_2', 'tn_prize_4d_55_3', 'tn_prize_4d_55_4',
            'tn_prize_4d_20_1',
"""

if 'tn_prize_abc' not in c:
    idx = c.find("'tn_sales_comm_4d_5") # After tn_sales_comm...
    # actually let's insert it before sales_comm_super
    idx = c.find("'sales_comm_super'")
    c = c[:idx] + fields_to_add + c[idx:]
    with open(p, 'w', encoding='utf-8') as f:
        f.write(c)
    print("serializers.py patched!")
else:
    print("already patched!")
