import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AdminNetRateScreen extends StatefulWidget {
  final UserModel? user;
  const AdminNetRateScreen({super.key, this.user});

  @override
  State<AdminNetRateScreen> createState() => _AdminNetRateScreenState();
}

class _AdminNetRateScreenState extends State<AdminNetRateScreen> {
  final _formKey = GlobalKey<FormState>();

  // KL Net Rate Controllers
  late TextEditingController _superNetController;
  late TextEditingController _abcNetController;
  late TextEditingController _abBcAcNetController;
  late TextEditingController _boxNetController;

  // TN Net Rate Controllers
  late TextEditingController _tnAbcNetController;
  late TextEditingController _tnAbBcAcNetController;
  late TextEditingController _tn3d10NetController;
  late TextEditingController _tn3d25NetController;
  late TextEditingController _tn3d30NetController;
  late TextEditingController _tn3d60NetController;
  late TextEditingController _tn4d110NetController;
  late TextEditingController _tn4d55NetController;
  late TextEditingController _tn4d20NetController;

  bool _isLoading = true;
  bool _isSaving = false;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    UserModel? user = widget.user;
    if (user == null) {
      final apiService = Provider.of<ApiService>(context, listen: false);
      user = await apiService.getProfile();
    }

    if (user != null) {
      _user = user;
      // Net Rate = Gross Price - Sales Commission
      // If commission is 0, default Net Rate is Gross Price
      double netSuper = user.priceSuper - user.salesCommSuper;
      double netAbc = user.priceAbc - user.salesCommAbc;
      double netAbBcAc = user.priceAbBcAc - user.salesCommAbBcAc;
      double netBox = user.priceBox - user.salesCommBox;

      double netTnAbc = user.tnPriceAbc - user.tnSalesCommAbc;
      double netTnAbBcAc = user.tnPriceAbBcAc - user.tnSalesCommAbBcAc;
      double netTn3d10 = user.tnPrice3d10 - user.tnSalesComm3d10;
      double netTn3d25 = user.tnPrice3d25 - user.tnSalesComm3d25;
      double netTn3d30 = user.tnPrice3d30 - user.tnSalesComm3d30;
      double netTn3d60 = user.tnPrice3d60 - user.tnSalesComm3d60;
      double netTn4d110 = user.tnPrice4d110 - user.tnSalesComm4d110;
      double netTn4d55 = user.tnPrice4d55 - user.tnSalesComm4d55;
      double netTn4d20 = user.tnPrice4d20 - user.tnSalesComm4d20;

      _superNetController = TextEditingController(text: _formatRate(netSuper));
      _abcNetController = TextEditingController(text: _formatRate(netAbc));
      _abBcAcNetController = TextEditingController(text: _formatRate(netAbBcAc));
      _boxNetController = TextEditingController(text: _formatRate(netBox));

      _tnAbcNetController = TextEditingController(text: _formatRate(netTnAbc));
      _tnAbBcAcNetController = TextEditingController(text: _formatRate(netTnAbBcAc));
      _tn3d10NetController = TextEditingController(text: _formatRate(netTn3d10));
      _tn3d25NetController = TextEditingController(text: _formatRate(netTn3d25));
      _tn3d30NetController = TextEditingController(text: _formatRate(netTn3d30));
      _tn3d60NetController = TextEditingController(text: _formatRate(netTn3d60));
      _tn4d110NetController = TextEditingController(text: _formatRate(netTn4d110));
      _tn4d55NetController = TextEditingController(text: _formatRate(netTn4d55));
      _tn4d20NetController = TextEditingController(text: _formatRate(netTn4d20));

      // Listeners for live commission recalculation in UI
      for (var c in [
        _superNetController,
        _abcNetController,
        _abBcAcNetController,
        _boxNetController,
        _tnAbcNetController,
        _tnAbBcAcNetController,
        _tn3d10NetController,
        _tn3d25NetController,
        _tn3d30NetController,
        _tn3d60NetController,
        _tn4d110NetController,
        _tn4d55NetController,
        _tn4d20NetController,
      ]) {
        c.addListener(() {
          if (mounted) setState(() {});
        });
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _formatRate(double val) {
    if (val == val.roundToDouble()) {
      return val.toStringAsFixed(0);
    }
    return val.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  @override
  void dispose() {
    if (!_isLoading) {
      _superNetController.dispose();
      _abcNetController.dispose();
      _abBcAcNetController.dispose();
      _boxNetController.dispose();

      _tnAbcNetController.dispose();
      _tnAbBcAcNetController.dispose();
      _tn3d10NetController.dispose();
      _tn3d25NetController.dispose();
      _tn3d30NetController.dispose();
      _tn3d60NetController.dispose();
      _tn4d110NetController.dispose();
      _tn4d55NetController.dispose();
      _tn4d20NetController.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _user == null) return;

    setState(() => _isSaving = true);
    final apiService = Provider.of<ApiService>(context, listen: false);

    // Calculate commission = Gross Price - Net Rate
    double parseNet(TextEditingController c, double grossDefault) {
      double? val = double.tryParse(c.text.trim());
      return val ?? grossDefault;
    }

    double netSuper = parseNet(_superNetController, _user!.priceSuper);
    double netAbc = parseNet(_abcNetController, _user!.priceAbc);
    double netAbBcAc = parseNet(_abBcAcNetController, _user!.priceAbBcAc);
    double netBox = parseNet(_boxNetController, _user!.priceBox);

    double netTnAbc = parseNet(_tnAbcNetController, _user!.tnPriceAbc);
    double netTnAbBcAc = parseNet(_tnAbBcAcNetController, _user!.tnPriceAbBcAc);
    double netTn3d10 = parseNet(_tn3d10NetController, _user!.tnPrice3d10);
    double netTn3d25 = parseNet(_tn3d25NetController, _user!.tnPrice3d25);
    double netTn3d30 = parseNet(_tn3d30NetController, _user!.tnPrice3d30);
    double netTn3d60 = parseNet(_tn3d60NetController, _user!.tnPrice3d60);
    double netTn4d110 = parseNet(_tn4d110NetController, _user!.tnPrice4d110);
    double netTn4d55 = parseNet(_tn4d55NetController, _user!.tnPrice4d55);
    double netTn4d20 = parseNet(_tn4d20NetController, _user!.tnPrice4d20);

    final data = {
      'sales_comm_super': (_user!.priceSuper - netSuper).clamp(0.0, _user!.priceSuper),
      'sales_comm_abc': (_user!.priceAbc - netAbc).clamp(0.0, _user!.priceAbc),
      'sales_comm_ab_bc_ac': (_user!.priceAbBcAc - netAbBcAc).clamp(0.0, _user!.priceAbBcAc),
      'sales_comm_box': (_user!.priceBox - netBox).clamp(0.0, _user!.priceBox),

      'tn_sales_comm_abc': (_user!.tnPriceAbc - netTnAbc).clamp(0.0, _user!.tnPriceAbc),
      'tn_sales_comm_ab_bc_ac': (_user!.tnPriceAbBcAc - netTnAbBcAc).clamp(0.0, _user!.tnPriceAbBcAc),
      'tn_sales_comm_3d_10': (_user!.tnPrice3d10 - netTn3d10).clamp(0.0, _user!.tnPrice3d10),
      'tn_sales_comm_3d_25': (_user!.tnPrice3d25 - netTn3d25).clamp(0.0, _user!.tnPrice3d25),
      'tn_sales_comm_3d_30': (_user!.tnPrice3d30 - netTn3d30).clamp(0.0, _user!.tnPrice3d30),
      'tn_sales_comm_3d_60': (_user!.tnPrice3d60 - netTn3d60).clamp(0.0, _user!.tnPrice3d60),
      'tn_sales_comm_4d_110': (_user!.tnPrice4d110 - netTn4d110).clamp(0.0, _user!.tnPrice4d110),
      'tn_sales_comm_4d_55': (_user!.tnPrice4d55 - netTn4d55).clamp(0.0, _user!.tnPrice4d55),
      'tn_sales_comm_4d_20': (_user!.tnPrice4d20 - netTn4d20).clamp(0.0, _user!.tnPrice4d20),
    };

    final success = await apiService.updateUser(_user!.id, data);
    setState(() => _isSaving = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Net Rate Settings updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update Net Rates'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'ADMIN NET RATE SETTINGS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 17,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Information banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade800, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'അഡ്മിൻ സ്വന്തമായി (SELF) ബുക്കിംഗ് ചെയ്യുമ്പോൾ ഈ നെറ്റ് റേറ്റാണ് ഈടാക്കുക.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // KL Section
                    if (_user == null || _user!.isKlEnabled) ...[
                      _buildSectionCard(
                        stateLabel: 'KL',
                        title: 'KL GAME NET RATES',
                        children: [
                          _buildDoubleNetField(
                            'SUPER',
                            _user!.priceSuper,
                            _superNetController,
                            'BOX',
                            _user!.priceBox,
                            _boxNetController,
                          ),
                          _buildDoubleNetField(
                            'A/B/C',
                            _user!.priceAbc,
                            _abcNetController,
                            'AB/BC/AC',
                            _user!.priceAbBcAc,
                            _abBcAcNetController,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // TN Section
                    if (_user == null || _user!.isTnEnabled) ...[
                      _buildSectionCard(
                        stateLabel: 'TN',
                        title: 'TN GAME NET RATES',
                        children: [
                          _buildDoubleNetField(
                            'A/B/C',
                            _user!.tnPriceAbc,
                            _tnAbcNetController,
                            'AB/BC/AC',
                            _user!.tnPriceAbBcAc,
                            _tnAbBcAcNetController,
                          ),
                          _buildDoubleNetField(
                            '3D-10',
                            _user!.tnPrice3d10,
                            _tn3d10NetController,
                            '3D-25',
                            _user!.tnPrice3d25,
                            _tn3d25NetController,
                          ),
                          _buildDoubleNetField(
                            '3D-30',
                            _user!.tnPrice3d30,
                            _tn3d30NetController,
                            '3D-60',
                            _user!.tnPrice3d60,
                            _tn3d60NetController,
                          ),
                          _buildDoubleNetField(
                            '4D-110',
                            _user!.tnPrice4d110,
                            _tn4d110NetController,
                            '4D-55',
                            _user!.tnPrice4d55,
                            _tn4d55NetController,
                          ),
                          _buildSingleNetField(
                            '4D-20',
                            _user!.tnPrice4d20,
                            _tn4d20NetController,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: AppColors.primary.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'SAVE NET RATES',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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

  Widget _buildDoubleNetField(
    String label1,
    double gross1,
    TextEditingController controller1,
    String label2,
    double gross2,
    TextEditingController controller2,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildNetField(label1, gross1, controller1)),
          const SizedBox(width: 12),
          Expanded(child: _buildNetField(label2, gross2, controller2)),
        ],
      ),
    );
  }

  Widget _buildSingleNetField(
    String label,
    double gross,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildNetField(label, gross, controller)),
          const SizedBox(width: 12),
          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildNetField(
    String label,
    double grossPrice,
    TextEditingController controller,
  ) {
    double? enteredNet = double.tryParse(controller.text.trim());
    double comm = (enteredNet != null) ? (grossPrice - enteredNet) : 0.0;
    bool isInvalid = enteredNet != null && (enteredNet > grossPrice || enteredNet <= 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Required';
            }
            double? parsed = double.tryParse(val.trim());
            if (parsed == null || parsed <= 0) {
              return 'Invalid';
            }
            if (parsed > grossPrice) {
              return 'Max ₹${_formatRate(grossPrice)}';
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: label.toUpperCase(),
            labelStyle: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            filled: true,
            fillColor: Colors.grey.shade50,
            isDense: true,
            suffixText: '₹',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: isInvalid ? Colors.red.shade300 : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: isInvalid ? Colors.red : AppColors.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Gross: ₹${_formatRate(grossPrice)}',
              style: TextStyle(
                fontSize: 10.5,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Comm: ₹${comm.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 10.5,
                color: comm < 0 ? Colors.red : Colors.green.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
