import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class ManagePrizeCommissionScreen extends StatefulWidget {
  final UserModel user;
  final bool isReadOnly;
  const ManagePrizeCommissionScreen(
      {super.key, required this.user, this.isReadOnly = false});

  @override
  State<ManagePrizeCommissionScreen> createState() =>
      _ManagePrizeCommissionScreenState();
}

class _ManagePrizeCommissionScreenState
    extends State<ManagePrizeCommissionScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // LSK SUPER
  final TextEditingController _superP1 = TextEditingController();
  final TextEditingController _superC1 = TextEditingController();
  final TextEditingController _superP2 = TextEditingController();
  final TextEditingController _superC2 = TextEditingController();
  final TextEditingController _superP3 = TextEditingController();
  final TextEditingController _superC3 = TextEditingController();
  final TextEditingController _superP4 = TextEditingController();
  final TextEditingController _superC4 = TextEditingController();
  final TextEditingController _superP5 = TextEditingController();
  final TextEditingController _superC5 = TextEditingController();

  // COMPLIMENTS
  final TextEditingController _prize6th = TextEditingController();
  final TextEditingController _comm6th = TextEditingController();

  // AB/BC/AC
  final TextEditingController _prizeAbBcAc = TextEditingController();
  final TextEditingController _commAbBcAc = TextEditingController();

  // A/B/C
  final TextEditingController _prizeAbc = TextEditingController();
  final TextEditingController _commAbc = TextEditingController();

  // BOX
  final TextEditingController _box3DP1 = TextEditingController();
  final TextEditingController _box3DC1 = TextEditingController();
  final TextEditingController _box3DP2 = TextEditingController();
  final TextEditingController _box3DC2 = TextEditingController();

  final TextEditingController _box2SP1 = TextEditingController();
  final TextEditingController _box2SC1 = TextEditingController();
  final TextEditingController _box2SP2 = TextEditingController();
  final TextEditingController _box2SC2 = TextEditingController();

  final TextEditingController _box3SP1 = TextEditingController();
  final TextEditingController _box3SC1 = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadValues();
  }

  void _loadValues() {
    _superP1.text = widget.user.prizeSuper1.toStringAsFixed(0);
    _superC1.text = widget.user.commSuper1.toStringAsFixed(0);
    _superP2.text = widget.user.prizeSuper2.toStringAsFixed(0);
    _superC2.text = widget.user.commSuper2.toStringAsFixed(0);
    _superP3.text = widget.user.prizeSuper3.toStringAsFixed(0);
    _superC3.text = widget.user.commSuper3.toStringAsFixed(0);
    _superP4.text = widget.user.prizeSuper4.toStringAsFixed(0);
    _superC4.text = widget.user.commSuper4.toStringAsFixed(0);
    _superP5.text = widget.user.prizeSuper5.toStringAsFixed(0);
    _superC5.text = widget.user.commSuper5.toStringAsFixed(0);

    _prize6th.text = widget.user.prize6th.toStringAsFixed(0);
    _comm6th.text = widget.user.comm6th.toStringAsFixed(0);

    _prizeAbBcAc.text = widget.user.prizeAbBcAc1.toStringAsFixed(0);
    _commAbBcAc.text = widget.user.commAbBcAc1.toStringAsFixed(0);

    _prizeAbc.text = widget.user.prizeAbc1.toStringAsFixed(0);
    _commAbc.text = widget.user.commAbc1.toStringAsFixed(0);

    _box3DP1.text = widget.user.prizeBox3d1.toStringAsFixed(0);
    _box3DC1.text = widget.user.commBox3d1.toStringAsFixed(0);
    _box3DP2.text = widget.user.prizeBox3d2.toStringAsFixed(0);
    _box3DC2.text = widget.user.commBox3d2.toStringAsFixed(0);

    _box2SP1.text = widget.user.prizeBox2s1.toStringAsFixed(0);
    _box2SC1.text = widget.user.commBox2s1.toStringAsFixed(0);
    _box2SP2.text = widget.user.prizeBox2s2.toStringAsFixed(0);
    _box2SC2.text = widget.user.commBox2s2.toStringAsFixed(0);

    _box3SP1.text = widget.user.prizeBox3s1.toStringAsFixed(0);
    _box3SC1.text = widget.user.commBox3s1.toStringAsFixed(0);
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);

    Map<String, dynamic> data = {
      'prize_super_1': double.tryParse(_superP1.text) ?? 0.0,
      'comm_super_1': double.tryParse(_superC1.text) ?? 0.0,
      'prize_super_2': double.tryParse(_superP2.text) ?? 0.0,
      'comm_super_2': double.tryParse(_superC2.text) ?? 0.0,
      'prize_super_3': double.tryParse(_superP3.text) ?? 0.0,
      'comm_super_3': double.tryParse(_superC3.text) ?? 0.0,
      'prize_super_4': double.tryParse(_superP4.text) ?? 0.0,
      'comm_super_4': double.tryParse(_superC4.text) ?? 0.0,
      'prize_super_5': double.tryParse(_superP5.text) ?? 0.0,
      'comm_super_5': double.tryParse(_superC5.text) ?? 0.0,
      'prize_6th': double.tryParse(_prize6th.text) ?? 0.0,
      'comm_6th': double.tryParse(_comm6th.text) ?? 0.0,
      'prize_ab_bc_ac_1': double.tryParse(_prizeAbBcAc.text) ?? 0.0,
      'comm_ab_bc_ac_1': double.tryParse(_commAbBcAc.text) ?? 0.0,
      'prize_abc_1': double.tryParse(_prizeAbc.text) ?? 0.0,
      'comm_abc_1': double.tryParse(_commAbc.text) ?? 0.0,
      'prize_box_3d_1': double.tryParse(_box3DP1.text) ?? 0.0,
      'comm_box_3d_1': double.tryParse(_box3DC1.text) ?? 0.0,
      'prize_box_3d_2': double.tryParse(_box3DP2.text) ?? 0.0,
      'comm_box_3d_2': double.tryParse(_box3DC2.text) ?? 0.0,
      'prize_box_2s_1': double.tryParse(_box2SP1.text) ?? 0.0,
      'comm_box_2s_1': double.tryParse(_box2SC1.text) ?? 0.0,
      'prize_box_2s_2': double.tryParse(_box2SP2.text) ?? 0.0,
      'comm_box_2s_2': double.tryParse(_box2SC2.text) ?? 0.0,
      'prize_box_3s_1': double.tryParse(_box3SP1.text) ?? 0.0,
      'comm_box_3s_1': double.tryParse(_box3SC1.text) ?? 0.0,
    };

    try {
      final success = await apiService.updateUser(widget.user.id, data);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Updated successfully')));
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text('Update failed. Please check your network or inputs.')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('PRIZE & COMMISSION',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 0.5)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!widget.isReadOnly)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('SAVE',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                              child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                                child: Text('PRIZE SETTINGS',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primary,
                                        letterSpacing: 1))),
                          )),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                                child: Text('COMMISSION',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF10B981),
                                        letterSpacing: 1))),
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: 'LSK SUPER',
                      icon: Icons.stars_rounded,
                      children: [
                        _buildDoubleRow(
                            '1ST PRIZE', _superP1, 'Commission', _superC1),
                        _buildDoubleRow(
                            '2ND PRIZE', _superP2, 'Commission', _superC2),
                        _buildDoubleRow(
                            '3RD PRIZE', _superP3, 'Commission', _superC3),
                        _buildDoubleRow(
                            '4TH PRIZE', _superP4, 'Commission', _superC4),
                        _buildDoubleRow(
                            '5TH PRIZE', _superP5, 'Commission', _superC5),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(height: 1, color: Colors.black12),
                        ),
                        Text('COMPLIMENTS SETTINGS',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.grey[400],
                                letterSpacing: 1)),
                        const SizedBox(height: 16),
                        _buildDoubleRow(
                            '6TH PRIZE', _prize6th, 'Commission', _comm6th),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: 'AB / BC / AC',
                      icon: Icons.layers_rounded,
                      children: [
                        _buildDoubleRow('1ST PRIZE', _prizeAbBcAc, 'Commission',
                            _commAbBcAc),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: 'A / B / C',
                      icon: Icons.format_list_numbered_rounded,
                      children: [
                        _buildDoubleRow(
                            '1ST PRIZE', _prizeAbc, 'Commission', _commAbc),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: 'BOX SETTINGS',
                      icon: Icons.grid_view_rounded,
                      children: [
                        _buildSubHeader('3 NUMBERS DIFFERENT'),
                        _buildDoubleRow(
                            '1ST PRIZE', _box3DP1, 'Commission', _box3DC1),
                        _buildDoubleRow(
                            '2ND PRIZE', _box3DP2, 'Commission', _box3DC2),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1, color: Colors.black12),
                        ),
                        _buildSubHeader('2 NUMBERS SAME'),
                        _buildDoubleRow(
                            '1ST PRIZE', _box2SP1, 'Commission', _box2SC1),
                        _buildDoubleRow(
                            '2ND PRIZE', _box2SP2, 'Commission', _box2SC2),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1, color: Colors.black12),
                        ),
                        _buildSubHeader('3 NUMBERS SAME'),
                        _buildDoubleRow(
                            '1ST PRIZE', _box3SP1, 'Commission', _box3SC1),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard(
      {required String title,
      required List<Widget> children,
      required IconData icon}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 8))
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSubHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(text,
          style: TextStyle(
              fontSize: 11,
              color: Colors.grey[400],
              fontWeight: FontWeight.w900,
              letterSpacing: 1)),
    );
  }

  Widget _buildDoubleRow(String pLabel, TextEditingController pController,
      String cLabel, TextEditingController cController) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Expanded(
              child: _buildTextField(pLabel, pController, AppColors.primary)),
          const SizedBox(width: 16),
          Expanded(
              child: _buildTextField(
                  cLabel, cController, const Color(0xFF10B981))),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        enabled: !widget.isReadOnly,
        style: const TextStyle(
            fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label.toUpperCase(),
          labelStyle: TextStyle(
              color: accentColor.withOpacity(0.6),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
