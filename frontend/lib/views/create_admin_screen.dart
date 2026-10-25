import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../models/user_model.dart';

class CreateAdminScreen extends StatefulWidget {
  final UserModel? user;
  const CreateAdminScreen({super.key, this.user});

  @override
  State<CreateAdminScreen> createState() => _CreateAdminScreenState();
}

class _CreateAdminScreenState extends State<CreateAdminScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _creditLimitController;

  bool _isLoading = false;
  bool _isDefault = false;
  String _subscriptionPlan = '30_days';
  int _maxAllowedGames = 4;
  String _gameMode = 'KL';
  bool _cutEnabled = false;
  String _cutType = 'percent';
  final TextEditingController _cutValueController = TextEditingController(text: '0');
  final List<String> _cutCategories = [
    'SUPER', 'BOX', 'AB', 'BC', 'AC', 'A', 'B', 'C',
    '3D-10', '3D-25', '3D-30', '3D-60', '4D-110', '4D-55', '4D-20'
  ];
  final Map<String, TextEditingController> _cutCatControllers = {};
  String _roleToSet = 'AGENT';
  String? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _usernameController =
        TextEditingController(text: widget.user?.username ?? '');
    _passwordController = TextEditingController();
    _creditLimitController = TextEditingController(
        text: widget.user?.weeklyCreditLimit.toString() ?? '0');
    if (widget.user != null) {
      _roleToSet = widget.user!.role;
      _isDefault = widget.user!.isDefault;
      _subscriptionPlan = widget.user!.subscriptionPlan;
      _maxAllowedGames = widget.user!.maxAllowedGames;
      _gameMode = widget.user!.gameMode;
      _cutEnabled = widget.user!.cutEnabled;
      _cutType = widget.user!.cutType;
      _cutValueController.text = widget.user!.cutValue.toString();
      final rawCats = widget.user!.cutCategoryValues;
      for (var cat in _cutCategories) {
        final val = rawCats[cat] ?? 0;
        _cutCatControllers[cat] = TextEditingController(text: val.toString());
      }
    } else {
      for (var cat in _cutCategories) {
        _cutCatControllers[cat] = TextEditingController(text: '0');
      }
    }
    _loadCurrentUserRole();
  }

  Future<void> _loadCurrentUserRole() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final profile = await apiService.getProfile();
    if (profile != null) {
      setState(() {
        _currentUserRole = profile.role;
        if (widget.user == null) {
          // Default role for new users based on creator
          if (_currentUserRole == 'SUPER_ADMIN') {
            _roleToSet = 'ADMIN';
          } else if (_currentUserRole == 'ADMIN') {
            _roleToSet = 'AGENT';
          } else if (_currentUserRole == 'AGENT') {
            _roleToSet = 'DEALER';
          } else if (_currentUserRole == 'DEALER') {
            _roleToSet = 'SUB_DEALER';
          }
        }
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final isEditing = widget.user != null;
    final apiService = Provider.of<ApiService>(context, listen: false);
    final userData = {
      'username': _usernameController.text,
      'role': _roleToSet,
      'weekly_credit_limit': _roleToSet == 'ADMIN' ? 0.0 : (double.tryParse(_creditLimitController.text) ?? 0.0),
      'is_default': _isDefault,
      'can_forward': false,
      'subscription_plan': _subscriptionPlan,
      'max_allowed_games': _maxAllowedGames,
      'game_mode': _gameMode,
      'cut_enabled': _cutEnabled,
      'cut_type': _cutType,
      'cut_value': double.tryParse(_cutValueController.text.trim()) ?? 0.0,
      'cut_category_values': {
        for (var e in _cutCatControllers.entries)
          if ((double.tryParse(e.value.text.trim()) ?? 0.0) > 0)
            e.key: double.tryParse(e.value.text.trim()) ?? 0.0
      },
    };

    if (!isEditing) {
      userData['price_abc'] = 12.0;
      userData['price_ab_bc_ac'] = 10.0;
      userData['price_super'] = 10.0;
      userData['price_box'] = 10.0;
    }

    if (_passwordController.text.isNotEmpty) {
      userData['password'] = _passwordController.text;
    }

    bool success;
    if (widget.user != null) {
      success = await apiService.updateUser(widget.user!.id, userData);
    } else {
      success = await apiService.createUser(userData);
    }

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        String msg = isEditing
            ? 'User updated successfully'
            : 'Account created successfully';
        if (_roleToSet == 'AGENT' && !isEditing)
          msg = 'Agent created successfully';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(widget.user != null
                ? 'Failed to update user'
                : 'Failed to create admin')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.user != null;
    return Scaffold(
      appBar: AppBar(
          title: Text(isEditing
              ? (widget.user?.role == 'AGENT' ? 'Edit Agent' : 'Edit User')
              : 'Create User')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Basic Information'),
              _buildTextField(_usernameController, 'Username', Icons.person),
              _buildTextField(
                  _passwordController,
                  'Password ${isEditing ? "(leave blank to keep current)" : ""}',
                  Icons.lock,
                  obscure: true,
                  required: !isEditing),
              const SizedBox(height: 20),
              _buildRoleDropdown(),
              const SizedBox(height: 20),
              if (_roleToSet != 'ADMIN') ...[
                _buildSectionTitle('Financial Limits'),
                _buildTextField(_creditLimitController, 'Weekly Credit Limit',
                    Icons.account_balance,
                    isNumber: true),
                const SizedBox(height: 20),
              ],
              if (_roleToSet == 'ADMIN') ...[
                _buildSectionTitle('Subscription & Game Package (സബ്സ്ക്രിപ്ഷൻ)'),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Subscription Plan (കാലാവധി)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _subscriptionPlan,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          prefixIcon: const Icon(Icons.card_membership_rounded, color: AppColors.primary),
                        ),
                        items: const [
                          DropdownMenuItem(value: '7_days', child: Text('7 Days (1 Week)')),
                          DropdownMenuItem(value: '30_days', child: Text('30 Days (1 Month)')),
                          DropdownMenuItem(value: '90_days', child: Text('90 Days (3 Months)')),
                          DropdownMenuItem(value: '180_days', child: Text('180 Days (6 Months)')),
                          DropdownMenuItem(value: '365_days', child: Text('365 Days (1 Year)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _subscriptionPlan = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Max Allowed Games (അനുവദിച്ച പരമാവധി ഗെയിമുകൾ)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _maxAllowedGames,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          prefixIcon: const Icon(Icons.games_rounded, color: Colors.deepOrange),
                        ),
                        items: const [
                          DropdownMenuItem(value: 4, child: Text('4 Games Limit')),
                          DropdownMenuItem(value: 8, child: Text('8 Games Limit')),
                          DropdownMenuItem(value: 12, child: Text('12 Games Limit')),
                          DropdownMenuItem(value: 16, child: Text('16 Games Limit')),
                          DropdownMenuItem(value: 24, child: Text('24 Games Limit')),
                          DropdownMenuItem(value: 999, child: Text('Unlimited Games')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _maxAllowedGames = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Game Model (ഏത് മോഡൽ വേണം?)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _gameMode,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          prefixIcon: const Icon(Icons.category_rounded, color: Colors.teal),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'KL', child: Text('KL (Kerala Only)')),
                          DropdownMenuItem(value: 'TN', child: Text('TN (Tamil Nadu Only)')),
                          DropdownMenuItem(value: 'BOTH', child: Text('Both (KL & TN)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _gameMode = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('Cut Settings (കട്ട് സെറ്റിംഗ്സ്)'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Enable Cut Option',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: const Text(
                            'Automatically cut a portion of bets from this Admin to Super Admin',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        value: _cutEnabled,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() {
                            _cutEnabled = val;
                          });
                        },
                      ),
                      if (_cutEnabled) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => setState(() => _cutType = 'percent'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: _cutType == 'percent' ? AppColors.primary : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Percentage (%)',
                                          style: TextStyle(
                                            color: _cutType == 'percent' ? Colors.white : Colors.black87,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => setState(() => _cutType = 'fixed_count'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: _cutType == 'fixed_count' ? AppColors.primary : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Fixed Count Limit',
                                          style: TextStyle(
                                            color: _cutType == 'fixed_count' ? Colors.white : Colors.black87,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              if (_cutType == 'percent') ...[
                                const Text('Cut Percentage to Super Admin (%):',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _cutValueController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    suffixText: '%',
                                    hintText: 'e.g. 20',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ] else ...[
                                const Text('Maximum Retained Count per Category (Excess cuts to Super Admin):',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                const SizedBox(height: 8),
                                ..._cutCategories.map((cat) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 80,
                                          child: Text(cat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        ),
                                        Expanded(
                                          child: SizedBox(
                                            height: 38,
                                            child: TextFormField(
                                              controller: _cutCatControllers[cat],
                                              keyboardType: TextInputType.number,
                                              decoration: InputDecoration(
                                                hintText: '0 (No cut)',
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isEditing ? 'UPDATE USER' : 'CREATE ADMIN',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    if (_currentUserRole == null)
      return const SizedBox(
          height: 50, child: Center(child: CircularProgressIndicator()));

    List<String> allowedRoles = [];
    if (_currentUserRole == 'SUPER_ADMIN') {
      allowedRoles = ['ADMIN', 'AGENT', 'DEALER', 'SUB_DEALER'];
    } else if (_currentUserRole == 'ADMIN') {
      allowedRoles = ['AGENT', 'DEALER', 'SUB_DEALER'];
    } else if (_currentUserRole == 'AGENT') {
      allowedRoles = ['DEALER', 'SUB_DEALER'];
    } else if (_currentUserRole == 'DEALER') {
      allowedRoles = ['SUB_DEALER'];
    }

    if (widget.user != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Text('ROLE: ${_roleToSet.replaceAll('_', ' ')}',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.grey)),
      );
    }

    return DropdownButtonFormField<String>(
      value: _roleToSet,
      items: allowedRoles
          .map((r) =>
              DropdownMenuItem(value: r, child: Text(r.replaceAll('_', ' '))))
          .toList(),
      onChanged: (val) => setState(() => _roleToSet = val!),
      decoration: InputDecoration(
        labelText: 'Account Role',
        prefixIcon: const Icon(Icons.security),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool obscure = false, bool isNumber = false, bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) => (required && value!.isEmpty) ? 'Required' : null,
      ),
    );
  }
}
