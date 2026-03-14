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
      'weekly_credit_limit': double.tryParse(_creditLimitController.text) ?? 0,
      'is_default': _isDefault,
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
              const SizedBox(height: 12),
              if (_roleToSet == 'SUB_DEALER') ...[
                CheckboxListTile(
                  title: const Text('Default ( Booking screen selection )',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text(
                      'Automatically select this user in booking screen',
                      style: TextStyle(fontSize: 11)),
                  value: _isDefault,
                  onChanged: (val) => setState(() => _isDefault = val ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primary,
                ),
                const SizedBox(height: 20),
              ],
              _buildSectionTitle('Financial Limits'),
              _buildTextField(_creditLimitController, 'Weekly Credit Limit',
                  Icons.account_balance,
                  isNumber: true),
              const SizedBox(height: 20),
              const SizedBox(height: 40),
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
