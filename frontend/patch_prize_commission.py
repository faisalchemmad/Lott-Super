import sys

p = r'd:\Gemini\Android\Lott_super\frontend\lib\views\manage_prize_commission_screen.dart'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()

# 1. Add Controllers
controllers_to_add = '''
  // TN Prizes
  final TextEditingController _tnPrizeAbc = TextEditingController();
  final TextEditingController _tnPrizeAbBcAc = TextEditingController();
  final TextEditingController _tnPrize3d10 = TextEditingController();
  final TextEditingController _tnPrize3d10Bc = TextEditingController();
  final TextEditingController _tnPrize3d25 = TextEditingController();
  final TextEditingController _tnPrize3d25Bc = TextEditingController();
  final TextEditingController _tnPrize3d30 = TextEditingController();
  final TextEditingController _tnPrize3d30Bc = TextEditingController();
  final TextEditingController _tnPrize3d30C = TextEditingController();
  final TextEditingController _tnPrize3d60 = TextEditingController();
  final TextEditingController _tnPrize3d60Bc = TextEditingController();
  final TextEditingController _tnPrize3d60C = TextEditingController();
  final TextEditingController _tnPrize4d110_1 = TextEditingController();
  final TextEditingController _tnPrize4d110_2 = TextEditingController();
  final TextEditingController _tnPrize4d110_3 = TextEditingController();
  final TextEditingController _tnPrize4d110_4 = TextEditingController();
  final TextEditingController _tnPrize4d55_1 = TextEditingController();
  final TextEditingController _tnPrize4d55_2 = TextEditingController();
  final TextEditingController _tnPrize4d55_3 = TextEditingController();
  final TextEditingController _tnPrize4d55_4 = TextEditingController();
  final TextEditingController _tnPrize4d20_1 = TextEditingController();
'''

if '_tnPrizeAbc' not in c:
    idx = c.find('final TextEditingController _box3SC1 = TextEditingController();')
    if idx != -1:
        c = c[:idx] + 'final TextEditingController _box3SC1 = TextEditingController();\n' + controllers_to_add + c[idx+len('final TextEditingController _box3SC1 = TextEditingController();'):]

# 2. Add load values
load_to_add = '''
    _tnPrizeAbc.text = widget.user.tnPrizeAbc.toStringAsFixed(0);
    _tnPrizeAbBcAc.text = widget.user.tnPrizeAbBcAc.toStringAsFixed(0);
    _tnPrize3d10.text = widget.user.tnPrize3d10.toStringAsFixed(0);
    _tnPrize3d10Bc.text = widget.user.tnPrize3d10Bc.toStringAsFixed(0);
    _tnPrize3d25.text = widget.user.tnPrize3d25.toStringAsFixed(0);
    _tnPrize3d25Bc.text = widget.user.tnPrize3d25Bc.toStringAsFixed(0);
    _tnPrize3d30.text = widget.user.tnPrize3d30.toStringAsFixed(0);
    _tnPrize3d30Bc.text = widget.user.tnPrize3d30Bc.toStringAsFixed(0);
    _tnPrize3d30C.text = widget.user.tnPrize3d30C.toStringAsFixed(0);
    _tnPrize3d60.text = widget.user.tnPrize3d60.toStringAsFixed(0);
    _tnPrize3d60Bc.text = widget.user.tnPrize3d60Bc.toStringAsFixed(0);
    _tnPrize3d60C.text = widget.user.tnPrize3d60C.toStringAsFixed(0);
    _tnPrize4d110_1.text = widget.user.tnPrize4d110_1.toStringAsFixed(0);
    _tnPrize4d110_2.text = widget.user.tnPrize4d110_2.toStringAsFixed(0);
    _tnPrize4d110_3.text = widget.user.tnPrize4d110_3.toStringAsFixed(0);
    _tnPrize4d110_4.text = widget.user.tnPrize4d110_4.toStringAsFixed(0);
    _tnPrize4d55_1.text = widget.user.tnPrize4d55_1.toStringAsFixed(0);
    _tnPrize4d55_2.text = widget.user.tnPrize4d55_2.toStringAsFixed(0);
    _tnPrize4d55_3.text = widget.user.tnPrize4d55_3.toStringAsFixed(0);
    _tnPrize4d55_4.text = widget.user.tnPrize4d55_4.toStringAsFixed(0);
    _tnPrize4d20_1.text = widget.user.tnPrize4d20_1.toStringAsFixed(0);
'''
if 'widget.user.tnPrizeAbc' not in c:
    idx = c.find('_box3SC1.text = widget.user.commBox3s1.toStringAsFixed(0);')
    if idx != -1:
        c = c[:idx] + '_box3SC1.text = widget.user.commBox3s1.toStringAsFixed(0);\n' + load_to_add + c[idx+len('_box3SC1.text = widget.user.commBox3s1.toStringAsFixed(0);'):]

# 3. Add save values
save_to_add = '''
      'tn_prize_abc': double.tryParse(_tnPrizeAbc.text) ?? 0.0,
      'tn_prize_ab_bc_ac': double.tryParse(_tnPrizeAbBcAc.text) ?? 0.0,
      'tn_prize_3d_10': double.tryParse(_tnPrize3d10.text) ?? 0.0,
      'tn_prize_3d_10_bc': double.tryParse(_tnPrize3d10Bc.text) ?? 0.0,
      'tn_prize_3d_25': double.tryParse(_tnPrize3d25.text) ?? 0.0,
      'tn_prize_3d_25_bc': double.tryParse(_tnPrize3d25Bc.text) ?? 0.0,
      'tn_prize_3d_30': double.tryParse(_tnPrize3d30.text) ?? 0.0,
      'tn_prize_3d_30_bc': double.tryParse(_tnPrize3d30Bc.text) ?? 0.0,
      'tn_prize_3d_30_c': double.tryParse(_tnPrize3d30C.text) ?? 0.0,
      'tn_prize_3d_60': double.tryParse(_tnPrize3d60.text) ?? 0.0,
      'tn_prize_3d_60_bc': double.tryParse(_tnPrize3d60Bc.text) ?? 0.0,
      'tn_prize_3d_60_c': double.tryParse(_tnPrize3d60C.text) ?? 0.0,
      'tn_prize_4d_110_1': double.tryParse(_tnPrize4d110_1.text) ?? 0.0,
      'tn_prize_4d_110_2': double.tryParse(_tnPrize4d110_2.text) ?? 0.0,
      'tn_prize_4d_110_3': double.tryParse(_tnPrize4d110_3.text) ?? 0.0,
      'tn_prize_4d_110_4': double.tryParse(_tnPrize4d110_4.text) ?? 0.0,
      'tn_prize_4d_55_1': double.tryParse(_tnPrize4d55_1.text) ?? 0.0,
      'tn_prize_4d_55_2': double.tryParse(_tnPrize4d55_2.text) ?? 0.0,
      'tn_prize_4d_55_3': double.tryParse(_tnPrize4d55_3.text) ?? 0.0,
      'tn_prize_4d_55_4': double.tryParse(_tnPrize4d55_4.text) ?? 0.0,
      'tn_prize_4d_20_1': double.tryParse(_tnPrize4d20_1.text) ?? 0.0,
'''
if "'tn_prize_abc'" not in c:
    idx = c.find("'comm_box_3s_1': double.tryParse(_box3SC1.text) ?? 0.0,")
    if idx != -1:
        c = c[:idx] + "'comm_box_3s_1': double.tryParse(_box3SC1.text) ?? 0.0,\n" + save_to_add + c[idx+len("'comm_box_3s_1': double.tryParse(_box3SC1.text) ?? 0.0,"):]


# 4. Insert UI modifications
ui_kl_header = '''
                    const SizedBox(height: 16),
                    const Center(child: Text('KL', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary))),
                    const SizedBox(height: 16),
'''

ui_tn_section = '''
                    const SizedBox(height: 32),
                    const Center(child: Text('TN', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary))),
                    const SizedBox(height: 16),
                    
                    _buildSectionCard(
                      title: 'A / B / C',
                      icon: Icons.format_list_numbered_rounded,
                      children: [
                        _buildSingleRow('PRIZE', _tnPrizeAbc),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: 'AB / BC / AC',
                      icon: Icons.layers_rounded,
                      children: [
                        _buildSingleRow('PRIZE', _tnPrizeAbBcAc),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: '3D GAMES',
                      icon: Icons.grid_3x3_rounded,
                      children: [
                        _buildSubHeader('3D-10'),
                        _buildDoubleRow('PRIZE', _tnPrize3d10, 'BC', _tnPrize3d10Bc),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Colors.black12)),
                        _buildSubHeader('3D-25'),
                        _buildDoubleRow('PRIZE', _tnPrize3d25, 'BC', _tnPrize3d25Bc),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Colors.black12)),
                        _buildSubHeader('3D-30'),
                        _buildTripleRow('PRIZE', _tnPrize3d30, 'BC', _tnPrize3d30Bc, 'C', _tnPrize3d30C),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Colors.black12)),
                        _buildSubHeader('3D-60'),
                        _buildTripleRow('PRIZE', _tnPrize3d60, 'BC', _tnPrize3d60Bc, 'C', _tnPrize3d60C),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: '4D GAMES',
                      icon: Icons.grid_4x4_rounded,
                      children: [
                        _buildSubHeader('4D-110'),
                        _buildDoubleRow('1ST PRIZE', _tnPrize4d110_1, '2ND PRIZE', _tnPrize4d110_2),
                        _buildDoubleRow('3RD PRIZE', _tnPrize4d110_3, '4TH PRIZE', _tnPrize4d110_4),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Colors.black12)),
                        _buildSubHeader('4D-55'),
                        _buildDoubleRow('1ST PRIZE', _tnPrize4d55_1, '2ND PRIZE', _tnPrize4d55_2),
                        _buildDoubleRow('3RD PRIZE', _tnPrize4d55_3, '4TH PRIZE', _tnPrize4d55_4),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Colors.black12)),
                        _buildSubHeader('4D-20'),
                        _buildSingleRow('1ST PRIZE', _tnPrize4d20_1),
                      ],
                    ),
                    const SizedBox(height: 40),
'''

if "'KL'" not in c:
    idx = c.find('const SizedBox(height: 24),\n                    _buildSectionCard(\n                      title: \'LSK SUPER\',')
    if idx != -1:
        c = c[:idx] + ui_kl_header + c[idx:]
    
    idx = c.find('const SizedBox(height: 40),\n                  ],\n                ),\n              ),\n            ),\n    );')
    if idx != -1:
        c = c[:idx] + ui_tn_section + c[idx+len('const SizedBox(height: 40),\n'):]

# 5. Add _buildSingleRow and _buildTripleRow
helpers_to_add = '''
  Widget _buildSingleRow(String label, TextEditingController controller, [Color? accentColor]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Expanded(child: _buildTextField(label, controller, accentColor ?? AppColors.primary)),
          const SizedBox(width: 16),
          Expanded(child: const SizedBox()), // Empty space to match layout
        ],
      ),
    );
  }

  Widget _buildTripleRow(String label1, TextEditingController controller1,
      String label2, TextEditingController controller2,
      String label3, TextEditingController controller3) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Expanded(child: _buildTextField(label1, controller1, AppColors.primary)),
          const SizedBox(width: 8),
          Expanded(child: _buildTextField(label2, controller2, AppColors.primary)),
          const SizedBox(width: 8),
          Expanded(child: _buildTextField(label3, controller3, AppColors.primary)),
        ],
      ),
    );
  }
'''

if '_buildSingleRow' not in c:
    idx = c.find('Widget _buildDoubleRow')
    if idx != -1:
        c = c[:idx] + helpers_to_add + '\n  ' + c[idx:]

with open(p, 'w', encoding='utf-8') as f:
    f.write(c)
print('UI Patched successfully!')
