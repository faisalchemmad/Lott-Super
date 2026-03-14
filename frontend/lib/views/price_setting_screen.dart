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
  late TextEditingController _abcController;
  late TextEditingController _abBcAcController;
  late TextEditingController _superController;
  late TextEditingController _boxController;
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
                              _abcController, 'ABC GAME PRICE', 'Default: 12'),
                          _buildPriceField(_abBcAcController, 'AB-BC-AC PRICE',
                              'Default: 10'),
                          _buildPriceField(_superController, 'SUPER GAME PRICE',
                              'Default: 10'),
                          _buildPriceField(
                              _boxController, 'BOX GAME PRICE', 'Default: 10'),
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
