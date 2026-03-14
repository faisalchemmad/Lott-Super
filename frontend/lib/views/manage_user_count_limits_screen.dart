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
  late TextEditingController _countA;
  late TextEditingController _countB;
  late TextEditingController _countC;
  late TextEditingController _countAB;
  late TextEditingController _countBC;
  late TextEditingController _countAC;
  late TextEditingController _countSuper;
  late TextEditingController _countBox;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _countA = TextEditingController(text: widget.user.countA.toString());
    _countB = TextEditingController(text: widget.user.countB.toString());
    _countC = TextEditingController(text: widget.user.countC.toString());
    _countAB = TextEditingController(text: widget.user.countAB.toString());
    _countBC = TextEditingController(text: widget.user.countBC.toString());
    _countAC = TextEditingController(text: widget.user.countAC.toString());
    _countSuper = TextEditingController(text: widget.user.countSuper.toString());
    _countBox = TextEditingController(text: widget.user.countBox.toString());
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
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final apiService = Provider.of<ApiService>(context, listen: false);
    final data = {
      'count_a': int.parse(_countA.text),
      'count_b': int.parse(_countB.text),
      'count_c': int.parse(_countC.text),
      'count_ab': int.parse(_countAB.text),
      'count_bc': int.parse(_countBC.text),
      'count_ac': int.parse(_countAC.text),
      'count_super': int.parse(_countSuper.text),
      'count_box': int.parse(_countBox.text),
    };

    try {
      final success = await apiService.updateUser(widget.user.id, data);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User Wise limits updated successfully!'), backgroundColor: Colors.green),
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
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildInfoCard(
                'These limits apply per-number for each bet type (e.g., if set to 250, every number from 000-999 allows up to 250 counts for this user).'),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Single Digit caps'),
                    const SizedBox(height: 12),
                    _buildGrid([
                      _buildLimitField('A Count', _countA, Icons.looks_one_rounded),
                      _buildLimitField('B Count', _countB, Icons.looks_two_rounded),
                      _buildLimitField('C Count', _countC, Icons.looks_3_rounded),
                    ]),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Double Digit caps'),
                    const SizedBox(height: 12),
                    _buildGrid([
                      _buildLimitField('AB Count', _countAB, Icons.filter_2_rounded),
                      _buildLimitField('BC Count', _countBC, Icons.filter_2_rounded),
                      _buildLimitField('AC Count', _countAC, Icons.filter_2_rounded),
                    ]),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Three Digit caps'),
                    const SizedBox(height: 12),
                    _buildGrid([
                      _buildLimitField('SUPER Count', _countSuper, Icons.star_rounded),
                      _buildLimitField('BOX Count', _countBox, Icons.inventory_2_rounded),
                    ]),
                    const SizedBox(height: 40),
                    if (!widget.isReadOnly) _buildUpdateButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String text) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.white, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 1.2),
    );
  }

  Widget _buildGrid(List<Widget> children) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: children,
    );
  }

  Widget _buildLimitField(String label, TextEditingController controller, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        enabled: !widget.isReadOnly,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: Colors.grey[400]),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('UPDATE USER WISE LIMITS',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }
}
