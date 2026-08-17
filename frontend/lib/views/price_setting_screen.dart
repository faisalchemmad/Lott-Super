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
        _abcController = TextEditingController(text: widget.user!.priceAbc.toString());
        _abBcAcController = TextEditingController(text: widget.user!.priceAbBcAc.toString());
        _superController = TextEditingController(text: widget.user!.priceSuper.toString());
        _boxController = TextEditingController(text: widget.user!.priceBox.toString());
        
        _tnAbcController = TextEditingController(text: widget.user!.tnPriceAbc.toString());
        _tnAbBcAcController = TextEditingController(text: widget.user!.tnPriceAbBcAc.toString());
        _tn3d10Controller = TextEditingController(text: widget.user!.tnPrice3d10.toString());
        _tn3d25Controller = TextEditingController(text: widget.user!.tnPrice3d25.toString());
        _tn3d30Controller = TextEditingController(text: widget.user!.tnPrice3d30.toString());
        _tn3d60Controller = TextEditingController(text: widget.user!.tnPrice3d60.toString());
        _tn4d110Controller = TextEditingController(text: widget.user!.tnPrice4d110.toString());
        _tn4d55Controller = TextEditingController(text: widget.user!.tnPrice4d55.toString());
        _tn4d20Controller = TextEditingController(text: widget.user!.tnPrice4d20.toString());
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
        _abBcAcController = TextEditingController(text: user.priceAbBcAc.toString());
        _superController = TextEditingController(text: user.priceSuper.toString());
        _boxController = TextEditingController(text: user.priceBox.toString());
        
        _tnAbcController = TextEditingController(text: user.tnPriceAbc.toString());
        _tnAbBcAcController = TextEditingController(text: user.tnPriceAbBcAc.toString());
        _tn3d10Controller = TextEditingController(text: user.tnPrice3d10.toString());
        _tn3d25Controller = TextEditingController(text: user.tnPrice3d25.toString());
        _tn3d30Controller = TextEditingController(text: user.tnPrice3d30.toString());
        _tn3d60Controller = TextEditingController(text: user.tnPrice3d60.toString());
        _tn4d110Controller = TextEditingController(text: user.tnPrice4d110.toString());
        _tn4d55Controller = TextEditingController(text: user.tnPrice4d55.toString());
        _tn4d20Controller = TextEditingController(text: user.tnPrice4d20.toString());
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
                                child: const Icon(
                                    Icons.settings_suggest_rounded,
                                    color: AppColors.primary,
                                    size: 24),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('PRICE MANAGEMENT',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black87,
                                          letterSpacing: 0.5)),
                                  Text('Set prices for all games',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[400])),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          _buildPriceField(
                              _abcController, 'KL ABC GAME PRICE', 'Default: 12'),
                          _buildPriceField(_abBcAcController, 'KL AB-BC-AC PRICE',
                              'Default: 10'),
                          _buildPriceField(_superController, 'KL SUPER GAME PRICE',
                              'Default: 10'),
                          _buildPriceField(
                              _boxController, 'KL BOX GAME PRICE', 'Default: 10'),
                          const Divider(height: 48, thickness: 1, color: Colors.black12),
                          _buildPriceField(
                              _tnAbcController, 'TN ABC GAME PRICE', 'Default: 12'),
                          _buildPriceField(_tnAbBcAcController, 'TN AB-BC-AC PRICE',
                              'Default: 10'),
                          _buildPriceField(_tn3d10Controller, 'TN 3D-10 PRICE', 'Default: 10'),
                          _buildPriceField(_tn3d25Controller, 'TN 3D-25 PRICE', 'Default: 25'),
                          _buildPriceField(_tn3d30Controller, 'TN 3D-30 PRICE', 'Default: 30'),
                          _buildPriceField(_tn3d60Controller, 'TN 3D-60 PRICE', 'Default: 60'),
                          _buildPriceField(_tn4d110Controller, 'TN 4D-110 PRICE', 'Default: 110'),
                          _buildPriceField(_tn4d55Controller, 'TN 4D-55 PRICE', 'Default: 55'),
                          _buildPriceField(_tn4d20Controller, 'TN 4D-20 PRICE', 'Default: 20'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: AppColors.primary.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
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

  Widget _buildPriceField(
      TextEditingController controller, String label, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withOpacity(0.02)),
            ),
            child: TextFormField(
              controller: controller,
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Colors.black87),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                    fontWeight: FontWeight.normal),
                prefixIcon: const Icon(Icons.currency_rupee_rounded,
                    size: 18, color: Colors.black26),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Required' : null,
            ),
          ),
        ],
      ),
    );
  }
}
