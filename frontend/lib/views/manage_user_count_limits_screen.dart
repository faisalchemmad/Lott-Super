import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class ManageUserCountLimitsScreen extends StatefulWidget {
  final UserModel user;
  final bool isReadOnly;
  const ManageUserCountLimitsScreen(
      {super.key, required this.user, this.isReadOnly = false});

  @override
  State<ManageUserCountLimitsScreen> createState() =>
      _ManageUserCountLimitsScreenState();
}

class _ManageUserCountLimitsScreenState
    extends State<ManageUserCountLimitsScreen> {
  final _formKey = GlobalKey<FormState>();

  // KL Controllers
  late TextEditingController _countA;
  late TextEditingController _countB;
  late TextEditingController _countC;
  late TextEditingController _countAB;
  late TextEditingController _countBC;
  late TextEditingController _countAC;
  late TextEditingController _countSuper;
  late TextEditingController _countBox;

  // TN Controllers
  late TextEditingController _tnCountA;
  late TextEditingController _tnCountB;
  late TextEditingController _tnCountC;
  late TextEditingController _tnCountAB;
  late TextEditingController _tnCountBC;
  late TextEditingController _tnCountAC;
  late TextEditingController _tnCount3d10;
  late TextEditingController _tnCount3d25;
  late TextEditingController _tnCount3d30;
  late TextEditingController _tnCount3d60;
  late TextEditingController _tnCount4d110;
  late TextEditingController _tnCount4d55;
  late TextEditingController _tnCount4d20;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // KL
    _countA = TextEditingController(text: widget.user.countA.toString());
    _countB = TextEditingController(text: widget.user.countB.toString());
    _countC = TextEditingController(text: widget.user.countC.toString());
    _countAB = TextEditingController(text: widget.user.countAB.toString());
    _countBC = TextEditingController(text: widget.user.countBC.toString());
    _countAC = TextEditingController(text: widget.user.countAC.toString());
    _countSuper =
        TextEditingController(text: widget.user.countSuper.toString());
    _countBox = TextEditingController(text: widget.user.countBox.toString());

    // TN
    _tnCountA = TextEditingController(text: widget.user.tnCountA.toString());
    _tnCountB = TextEditingController(text: widget.user.tnCountB.toString());
    _tnCountC = TextEditingController(text: widget.user.tnCountC.toString());
    _tnCountAB = TextEditingController(text: widget.user.tnCountAB.toString());
    _tnCountBC = TextEditingController(text: widget.user.tnCountBC.toString());
    _tnCountAC = TextEditingController(text: widget.user.tnCountAC.toString());
    _tnCount3d10 =
        TextEditingController(text: widget.user.tnCount3d10.toString());
    _tnCount3d25 =
        TextEditingController(text: widget.user.tnCount3d25.toString());
    _tnCount3d30 =
        TextEditingController(text: widget.user.tnCount3d30.toString());
    _tnCount3d60 =
        TextEditingController(text: widget.user.tnCount3d60.toString());
    _tnCount4d110 =
        TextEditingController(text: widget.user.tnCount4d110.toString());
    _tnCount4d55 =
        TextEditingController(text: widget.user.tnCount4d55.toString());
    _tnCount4d20 =
        TextEditingController(text: widget.user.tnCount4d20.toString());

    _loadFreshUserData();
  }

  Future<void> _loadFreshUserData() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final users = await apiService.getUsers();
      final u = users.firstWhere((usr) => usr.id == widget.user.id);
      if (mounted) {
        setState(() {
          _countA.text = u.countA.toString();
          _countB.text = u.countB.toString();
          _countC.text = u.countC.toString();
          _countAB.text = u.countAB.toString();
          _countBC.text = u.countBC.toString();
          _countAC.text = u.countAC.toString();
          _countSuper.text = u.countSuper.toString();
          _countBox.text = u.countBox.toString();

          _tnCountA.text = u.tnCountA.toString();
          _tnCountB.text = u.tnCountB.toString();
          _tnCountC.text = u.tnCountC.toString();
          _tnCountAB.text = u.tnCountAB.toString();
          _tnCountBC.text = u.tnCountBC.toString();
          _tnCountAC.text = u.tnCountAC.toString();
          _tnCount3d10.text = u.tnCount3d10.toString();
          _tnCount3d25.text = u.tnCount3d25.toString();
          _tnCount3d30.text = u.tnCount3d30.toString();
          _tnCount3d60.text = u.tnCount3d60.toString();
          _tnCount4d110.text = u.tnCount4d110.toString();
          _tnCount4d55.text = u.tnCount4d55.toString();
          _tnCount4d20.text = u.tnCount4d20.toString();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _countA.dispose();
    _countB.dispose();
    _countC.dispose();
    _countAB.dispose();
    _countBC.dispose();
    _countAC.dispose();
    _countSuper.dispose();
    _countBox.dispose();

    _tnCountA.dispose();
    _tnCountB.dispose();
    _tnCountC.dispose();
    _tnCountAB.dispose();
    _tnCountBC.dispose();
    _tnCountAC.dispose();
    _tnCount3d10.dispose();
    _tnCount3d25.dispose();
    _tnCount3d30.dispose();
    _tnCount3d60.dispose();
    _tnCount4d110.dispose();
    _tnCount4d55.dispose();
    _tnCount4d20.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final apiService = Provider.of<ApiService>(context, listen: false);
    final data = {
      // KL
      'count_a': int.tryParse(_countA.text.trim()) ?? 0,
      'count_b': int.tryParse(_countB.text.trim()) ?? 0,
      'count_c': int.tryParse(_countC.text.trim()) ?? 0,
      'count_ab': int.tryParse(_countAB.text.trim()) ?? 0,
      'count_bc': int.tryParse(_countBC.text.trim()) ?? 0,
      'count_ac': int.tryParse(_countAC.text.trim()) ?? 0,
      'count_super': int.tryParse(_countSuper.text.trim()) ?? 0,
      'count_box': int.tryParse(_countBox.text.trim()) ?? 0,
      // TN
      'tn_count_a': int.tryParse(_tnCountA.text.trim()) ?? 0,
      'tn_count_b': int.tryParse(_tnCountB.text.trim()) ?? 0,
      'tn_count_c': int.tryParse(_tnCountC.text.trim()) ?? 0,
      'tn_count_ab': int.tryParse(_tnCountAB.text.trim()) ?? 0,
      'tn_count_bc': int.tryParse(_tnCountBC.text.trim()) ?? 0,
      'tn_count_ac': int.tryParse(_tnCountAC.text.trim()) ?? 0,
      'tn_count_3d_10': int.tryParse(_tnCount3d10.text.trim()) ?? 0,
      'tn_count_3d_25': int.tryParse(_tnCount3d25.text.trim()) ?? 0,
      'tn_count_3d_30': int.tryParse(_tnCount3d30.text.trim()) ?? 0,
      'tn_count_3d_60': int.tryParse(_tnCount3d60.text.trim()) ?? 0,
      'tn_count_4d_110': int.tryParse(_tnCount4d110.text.trim()) ?? 0,
      'tn_count_4d_55': int.tryParse(_tnCount4d55.text.trim()) ?? 0,
      'tn_count_4d_20': int.tryParse(_tnCount4d20.text.trim()) ?? 0,
    };

    try {
      final success = await apiService.updateUser(widget.user.id, data);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('User Wise limits updated successfully!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('${widget.user.username} User Wise Limits',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildKlSection(),
                const SizedBox(height: 16),
                _buildTnSection(),
                const SizedBox(height: 24),
                if (!widget.isReadOnly) _buildUpdateButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKlSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border:
            Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'KL',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'KERALA COUNT LIMITS',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.primary,
                    letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSectionTitle('Single Digit caps'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _buildLimitField(
                      'A Count', _countA, Icons.looks_one_rounded)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildLimitField(
                      'B Count', _countB, Icons.looks_two_rounded)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildLimitField(
                      'C Count', _countC, Icons.looks_3_rounded)),
            ],
          ),
          const SizedBox(height: 14),
          _buildSectionTitle('Double Digit caps'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _buildLimitField(
                      'AB Count', _countAB, Icons.filter_2_rounded)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildLimitField(
                      'BC Count', _countBC, Icons.filter_2_rounded)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildLimitField(
                      'AC Count', _countAC, Icons.filter_2_rounded)),
            ],
          ),
          const SizedBox(height: 14),
          _buildSectionTitle('Three Digit caps'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _buildLimitField(
                      'SUPER Count', _countSuper, Icons.star_rounded)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildLimitField(
                      'BOX Count', _countBox, Icons.inventory_2_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTnSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border:
            Border.all(color: Colors.deepOrange.withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.deepOrange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'TN',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'TAMIL NADU COUNT LIMITS',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.deepOrange,
                    letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSectionTitle('TN Single Digit caps', Colors.deepOrange),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _buildLimitField('A Count', _tnCountA,
                      Icons.looks_one_rounded, Colors.deepOrange)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildLimitField('B Count', _tnCountB,
                      Icons.looks_two_rounded, Colors.deepOrange)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildLimitField('C Count', _tnCountC,
                      Icons.looks_3_rounded, Colors.deepOrange)),
            ],
          ),
          const SizedBox(height: 14),
          _buildSectionTitle('TN Double Digit caps', Colors.deepOrange),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _buildLimitField('AB Count', _tnCountAB,
                      Icons.filter_2_rounded, Colors.deepOrange)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildLimitField('BC Count', _tnCountBC,
                      Icons.filter_2_rounded, Colors.deepOrange)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildLimitField('AC Count', _tnCountAC,
                      Icons.filter_2_rounded, Colors.deepOrange)),
            ],
          ),
          const SizedBox(height: 14),
          _buildSectionTitle('TN 3 Digit caps', Colors.deepOrange),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _buildLimitField('3D-10', _tnCount3d10,
                      Icons.star_rounded, Colors.deepOrange)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildLimitField('3D-25', _tnCount3d25,
                      Icons.star_rounded, Colors.deepOrange)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _buildLimitField('3D-30', _tnCount3d30,
                      Icons.star_rounded, Colors.deepOrange)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildLimitField('3D-60', _tnCount3d60,
                      Icons.star_rounded, Colors.deepOrange)),
            ],
          ),
          const SizedBox(height: 14),
          _buildSectionTitle('TN 4 Digit caps', Colors.deepOrange),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _buildLimitField('4D-110', _tnCount4d110,
                      Icons.inventory_2_rounded, Colors.deepOrange)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildLimitField('4D-55', _tnCount4d55,
                      Icons.inventory_2_rounded, Colors.deepOrange)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildLimitField('4D-20', _tnCount4d20,
                      Icons.inventory_2_rounded, Colors.deepOrange)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, [Color color = AppColors.primary]) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5),
    );
  }

  Widget _buildLimitField(String label, TextEditingController controller,
      [IconData? icon, Color activeColor = AppColors.primary]) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      enabled: !widget.isReadOnly,
      style: const TextStyle(
          fontWeight: FontWeight.w900, fontSize: 13, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label.toUpperCase(),
        labelStyle: TextStyle(
            color: activeColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        prefixIcon:
            icon != null ? Icon(icon, size: 14, color: activeColor) : null,
        prefixIconConstraints: icon != null
            ? const BoxConstraints(minWidth: 24, minHeight: 24)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: activeColor, width: 1.5),
        ),
      ),
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Required' : null,
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 4,
          shadowColor: AppColors.primary.withOpacity(0.4),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Text('UPDATE USER WISE LIMITS',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
      ),
    );
  }
}
