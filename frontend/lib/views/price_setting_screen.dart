import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class PriceSettingScreen extends StatefulWidget {
  final UserModel? user;
  const PriceSettingScreen({super.key, this.user});

  @override
  State<PriceSettingScreen> createState() => _PriceSettingScreenState();
}

class _PriceSettingScreenState extends State<PriceSettingScreen> {
  final _formKey = GlobalKey<FormState>();
  // KL Controllers
  late TextEditingController _abcController;
  late TextEditingController _abBcAcController;
  late TextEditingController _superController;
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

  bool _isLoading = true;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (widget.user != null) {
      setState(() {
        _user = widget.user;
        _abcController =
            TextEditingController(text: widget.user!.priceAbc.toString());
        _abBcAcController =
            TextEditingController(text: widget.user!.priceAbBcAc.toString());
        _superController =
            TextEditingController(text: widget.user!.priceSuper.toString());
        _boxController =
            TextEditingController(text: widget.user!.priceBox.toString());

        _tnAbcController =
            TextEditingController(text: widget.user!.tnPriceAbc.toString());
        _tnAbBcAcController =
            TextEditingController(text: widget.user!.tnPriceAbBcAc.toString());
        _tn3d10Controller =
            TextEditingController(text: widget.user!.tnPrice3d10.toString());
        _tn3d25Controller =
            TextEditingController(text: widget.user!.tnPrice3d25.toString());
        _tn3d30Controller =
            TextEditingController(text: widget.user!.tnPrice3d30.toString());
        _tn3d60Controller =
            TextEditingController(text: widget.user!.tnPrice3d60.toString());
        _tn4d110Controller =
            TextEditingController(text: widget.user!.tnPrice4d110.toString());
        _tn4d55Controller =
            TextEditingController(text: widget.user!.tnPrice4d55.toString());
        _tn4d20Controller =
            TextEditingController(text: widget.user!.tnPrice4d20.toString());
        _isLoading = false;
      });
      return;
    }

    final apiService = Provider.of<ApiService>(context, listen: false);
    final user = await apiService.getProfile();
    if (user != null) {
      setState(() {
        _user = user;
        _abcController = TextEditingController(text: user.priceAbc.toString());
        _abBcAcController =
            TextEditingController(text: user.priceAbBcAc.toString());
        _superController =
            TextEditingController(text: user.priceSuper.toString());
        _boxController = TextEditingController(text: user.priceBox.toString());

        _tnAbcController =
            TextEditingController(text: user.tnPriceAbc.toString());
        _tnAbBcAcController =
            TextEditingController(text: user.tnPriceAbBcAc.toString());
        _tn3d10Controller =
            TextEditingController(text: user.tnPrice3d10.toString());
        _tn3d25Controller =
            TextEditingController(text: user.tnPrice3d25.toString());
        _tn3d30Controller =
            TextEditingController(text: user.tnPrice3d30.toString());
        _tn3d60Controller =
            TextEditingController(text: user.tnPrice3d60.toString());
        _tn4d110Controller =
            TextEditingController(text: user.tnPrice4d110.toString());
        _tn4d55Controller =
            TextEditingController(text: user.tnPrice4d55.toString());
        _tn4d20Controller =
            TextEditingController(text: user.tnPrice4d20.toString());
        _isLoading = false;
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final apiService = Provider.of<ApiService>(context, listen: false);
    final data = {
      'price_abc': double.tryParse(_abcController.text) ?? 12.0,
      'price_ab_bc_ac': double.tryParse(_abBcAcController.text) ?? 10.0,
      'price_super': double.tryParse(_superController.text) ?? 10.0,
      'price_box': double.tryParse(_boxController.text) ?? 10.0,
      'tn_price_abc': double.tryParse(_tnAbcController.text) ?? 12.0,
      'tn_price_ab_bc_ac': double.tryParse(_tnAbBcAcController.text) ?? 10.0,
      'tn_price_3d_10': double.tryParse(_tn3d10Controller.text) ?? 10.0,
      'tn_price_3d_25': double.tryParse(_tn3d25Controller.text) ?? 25.0,
      'tn_price_3d_30': double.tryParse(_tn3d30Controller.text) ?? 30.0,
      'tn_price_3d_60': double.tryParse(_tn3d60Controller.text) ?? 60.0,
      'tn_price_4d_110': double.tryParse(_tn4d110Controller.text) ?? 110.0,
      'tn_price_4d_55': double.tryParse(_tn4d55Controller.text) ?? 55.0,
      'tn_price_4d_20': double.tryParse(_tn4d20Controller.text) ?? 20.0,
    };

    final success = await apiService.updateUser(_user!.id, data);
    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Price Settings updated successfully')));
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update prices')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('GAME PRICE SETTINGS',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionCard(
                      stateLabel: 'KL',
                      title: 'KL GAME PRICES',
                      children: [
                        _buildDoubleField(
                          'SUPER',
                          _superController,
                          'Default: 10',
                          'BOX',
                          _boxController,
                          'Default: 10',
                        ),
                        _buildDoubleField(
                          'A/B/C',
                          _abcController,
                          'Default: 12',
                          'AB/BC/AC',
                          _abBcAcController,
                          'Default: 10',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      stateLabel: 'TN',
                      title: 'TN GAME PRICES',
                      children: [
                        _buildDoubleField(
                          'A/B/C',
                          _tnAbcController,
                          'Default: 12',
                          'AB/BC/AC',
                          _tnAbBcAcController,
                          'Default: 10',
                        ),
                        _buildDoubleField(
                          '3D-10',
                          _tn3d10Controller,
                          'Default: 10',
                          '3D-25',
                          _tn3d25Controller,
                          'Default: 25',
                        ),
                        _buildDoubleField(
                          '3D-30',
                          _tn3d30Controller,
                          'Default: 30',
                          '3D-60',
                          _tn3d60Controller,
                          'Default: 60',
                        ),
                        _buildDoubleField(
                          '4D-110',
                          _tn4d110Controller,
                          'Default: 110',
                          '4D-55',
                          _tn4d55Controller,
                          'Default: 55',
                        ),
                        _buildSingleField(
                          '4D-20',
                          _tn4d20Controller,
                          'Default: 20',
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: AppColors.primary.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text('UPDATE PRICE SETTINGS',
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

  Widget _buildSectionCard({
    required String stateLabel,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  stateLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDoubleField(
      String label1,
      TextEditingController controller1,
      String hint1,
      String label2,
      TextEditingController controller2,
      String hint2) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(child: _buildPriceField(controller1, label1, hint1)),
          const SizedBox(width: 12),
          Expanded(child: _buildPriceField(controller2, label2, hint2)),
        ],
      ),
    );
  }

  Widget _buildSingleField(
      String label, TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(child: _buildPriceField(controller, label, hint)),
          const SizedBox(width: 12),
          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildPriceField(
      TextEditingController controller, String label, String hint) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(
          fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black87),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label.toUpperCase(),
        labelStyle: const TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        prefixIcon: const Icon(Icons.currency_rupee_rounded,
            size: 16, color: AppColors.primary),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Required' : null,
    );
  }
}
