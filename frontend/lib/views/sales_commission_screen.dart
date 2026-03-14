import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class SalesCommissionScreen extends StatefulWidget {
  final UserModel user;
  const SalesCommissionScreen({super.key, required this.user});

  @override
  State<SalesCommissionScreen> createState() => _SalesCommissionScreenState();
}

class _SalesCommissionScreenState extends State<SalesCommissionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _superController;
  late TextEditingController _abcController;
  late TextEditingController _abBcAcController;
  late TextEditingController _boxController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _superController =
        TextEditingController(text: widget.user.salesCommSuper.toString());
    _abcController =
        TextEditingController(text: widget.user.salesCommAbc.toString());
    _abBcAcController =
        TextEditingController(text: widget.user.salesCommAbBcAc.toString());
    _boxController =
        TextEditingController(text: widget.user.salesCommBox.toString());
  }

  @override
  void dispose() {
    _superController.dispose();
    _abcController.dispose();
    _abBcAcController.dispose();
    _boxController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);

    final data = {
      'sales_comm_super': double.tryParse(_superController.text) ?? 0.0,
      'sales_comm_abc': double.tryParse(_abcController.text) ?? 0.0,
      'sales_comm_ab_bc_ac': double.tryParse(_abBcAcController.text) ?? 0.0,
      'sales_comm_box': double.tryParse(_boxController.text) ?? 0.0,
    };

    try {
      final success = await apiService.updateUser(widget.user.id, data);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Sales Commission updated successfully')),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Failed to update');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
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
        title: const Text('SALES COMMISSION',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 0.5)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildCommissionField('LSK SUPER', _superController),
                    const SizedBox(height: 24),
                    _buildCommissionField('A/B/C', _abcController),
                    const SizedBox(height: 24),
                    _buildCommissionField('AB/BC/AC', _abBcAcController),
                    const SizedBox(height: 24),
                    _buildCommissionField('Box', _boxController),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: AppColors.primary.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('UPDATE COMMISSION',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommissionField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            ),
          ),
        ),
      ],
    );
  }
}
