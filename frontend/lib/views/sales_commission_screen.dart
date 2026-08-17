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
  
  // KL Controllers
  late TextEditingController _superController;
  late TextEditingController _abcController;
  late TextEditingController _abBcAcController;
  late TextEditingController _boxController;
  
  // TN Controllers
  late TextEditingController _tnAbcController;
  late TextEditingController _tnAbBcAcController;
  late TextEditingController _tn3d10Controller;
  late TextEditingController _tn3d25Controller;
  late TextEditingController _tn3d30Controller;
  late TextEditingController _tn3d60Controller;
  late TextEditingController _tn4d110Controller;
  late TextEditingController _tn4d55Controller;
  late TextEditingController _tn4d20Controller;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _superController = TextEditingController(text: widget.user.salesCommSuper.toString());
    _abcController = TextEditingController(text: widget.user.salesCommAbc.toString());
    _abBcAcController = TextEditingController(text: widget.user.salesCommAbBcAc.toString());
    _boxController = TextEditingController(text: widget.user.salesCommBox.toString());
    
    _tnAbcController = TextEditingController(text: widget.user.tnSalesCommAbc.toString());
    _tnAbBcAcController = TextEditingController(text: widget.user.tnSalesCommAbBcAc.toString());
    _tn3d10Controller = TextEditingController(text: widget.user.tnSalesComm3d10.toString());
    _tn3d25Controller = TextEditingController(text: widget.user.tnSalesComm3d25.toString());
    _tn3d30Controller = TextEditingController(text: widget.user.tnSalesComm3d30.toString());
    _tn3d60Controller = TextEditingController(text: widget.user.tnSalesComm3d60.toString());
    _tn4d110Controller = TextEditingController(text: widget.user.tnSalesComm4d110.toString());
    _tn4d55Controller = TextEditingController(text: widget.user.tnSalesComm4d55.toString());
    _tn4d20Controller = TextEditingController(text: widget.user.tnSalesComm4d20.toString());
  }

  @override
  void dispose() {
    _superController.dispose();
    _abcController.dispose();
    _abBcAcController.dispose();
    _boxController.dispose();
    
    _tnAbcController.dispose();
    _tnAbBcAcController.dispose();
    _tn3d10Controller.dispose();
    _tn3d25Controller.dispose();
    _tn3d30Controller.dispose();
    _tn3d60Controller.dispose();
    _tn4d110Controller.dispose();
    _tn4d55Controller.dispose();
    _tn4d20Controller.dispose();
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
      
      'tn_sales_comm_abc': double.tryParse(_tnAbcController.text) ?? 0.0,
      'tn_sales_comm_ab_bc_ac': double.tryParse(_tnAbBcAcController.text) ?? 0.0,
      'tn_sales_comm_3d_10': double.tryParse(_tn3d10Controller.text) ?? 0.0,
      'tn_sales_comm_3d_25': double.tryParse(_tn3d25Controller.text) ?? 0.0,
      'tn_sales_comm_3d_30': double.tryParse(_tn3d30Controller.text) ?? 0.0,
      'tn_sales_comm_3d_60': double.tryParse(_tn3d60Controller.text) ?? 0.0,
      'tn_sales_comm_4d_110': double.tryParse(_tn4d110Controller.text) ?? 0.0,
      'tn_sales_comm_4d_55': double.tryParse(_tn4d55Controller.text) ?? 0.0,
      'tn_sales_comm_4d_20': double.tryParse(_tn4d20Controller.text) ?? 0.0,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.percent_rounded,
                              color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('COMMISSION SETTINGS',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black87,
                                    letterSpacing: 0.5)),
                            Text('Set sales commission rates',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[400])),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildCommissionField('KL LSK SUPER', _superController),
                    _buildCommissionField('KL A/B/C', _abcController),
                    _buildCommissionField('KL AB/BC/AC', _abBcAcController),
                    _buildCommissionField('KL Box', _boxController),
                    const Divider(height: 48, thickness: 1, color: Colors.black12),
                    _buildCommissionField('TN A/B/C', _tnAbcController),
                    _buildCommissionField('TN AB/BC/AC', _tnAbBcAcController),
                    _buildCommissionField('TN 3D-10', _tn3d10Controller),
                    _buildCommissionField('TN 3D-25', _tn3d25Controller),
                    _buildCommissionField('TN 3D-30', _tn3d30Controller),
                    _buildCommissionField('TN 3D-60', _tn3d60Controller),
                    _buildCommissionField('TN 4D-110', _tn4d110Controller),
                    _buildCommissionField('TN 4D-55', _tn4d55Controller),
                    _buildCommissionField('TN 4D-20', _tn4d20Controller),
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
