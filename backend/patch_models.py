import sys

p = r'd:\Gemini\Android\Lott_super\backend\core\models.py'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()

fields = """
    # TN Prize Settings
    tn_prize_abc = models.DecimalField(max_digits=10, decimal_places=2, default=1000.0)
    tn_prize_ab_bc_ac = models.DecimalField(max_digits=10, decimal_places=2, default=1000.0)
    tn_prize_3d_10 = models.DecimalField(max_digits=10, decimal_places=2, default=5000.0)
    tn_prize_3d_10_bc = models.DecimalField(max_digits=10, decimal_places=2, default=100.0)
    tn_prize_3d_25 = models.DecimalField(max_digits=10, decimal_places=2, default=10000.0)
    tn_prize_3d_25_bc = models.DecimalField(max_digits=10, decimal_places=2, default=1000.0)
    tn_prize_3d_30 = models.DecimalField(max_digits=10, decimal_places=2, default=15000.0)
    tn_prize_3d_30_bc = models.DecimalField(max_digits=10, decimal_places=2, default=500.0)
    tn_prize_3d_30_c = models.DecimalField(max_digits=10, decimal_places=2, default=50.0)
    tn_prize_3d_60 = models.DecimalField(max_digits=10, decimal_places=2, default=30000.0)
    tn_prize_3d_60_bc = models.DecimalField(max_digits=10, decimal_places=2, default=1000.0)
    tn_prize_3d_60_c = models.DecimalField(max_digits=10, decimal_places=2, default=100.0)
    tn_prize_4d_110_1 = models.DecimalField(max_digits=10, decimal_places=2, default=450000.0)
    tn_prize_4d_110_2 = models.DecimalField(max_digits=10, decimal_places=2, default=10000.0)
    tn_prize_4d_110_3 = models.DecimalField(max_digits=10, decimal_places=2, default=1000.0)
    tn_prize_4d_110_4 = models.DecimalField(max_digits=10, decimal_places=2, default=100.0)
    tn_prize_4d_55_1 = models.DecimalField(max_digits=10, decimal_places=2, default=225000.0)
    tn_prize_4d_55_2 = models.DecimalField(max_digits=10, decimal_places=2, default=5000.0)
    tn_prize_4d_55_3 = models.DecimalField(max_digits=10, decimal_places=2, default=500.0)
    tn_prize_4d_55_4 = models.DecimalField(max_digits=10, decimal_places=2, default=50.0)
    tn_prize_4d_20_1 = models.DecimalField(max_digits=10, decimal_places=2, default=100000.0)
"""

if 'tn_prize_abc' not in c:
    idx = c.find('tn_sales_comm_4d_20 = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)')
    idx = c.find('\n', idx) + 1
    c = c[:idx] + fields + c[idx:]
    with open(p, 'w', encoding='utf-8') as f:
        f.write(c)
    print("models.py patched!")
else:
    print("already patched!")
