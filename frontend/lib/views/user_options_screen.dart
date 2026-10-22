import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'create_admin_screen.dart';
import 'user_game_limit_screen.dart';
import 'manage_user_game_timings_screen.dart';
import 'manage_prize_commission_screen.dart';
import 'price_setting_screen.dart';
import 'sales_commission_screen.dart';
import 'manage_user_game_permissions_screen.dart';

class UserOptionsScreen extends StatefulWidget {
  final UserModel user;
  const UserOptionsScreen({super.key, required this.user});

  @override
  State<UserOptionsScreen> createState() => _UserOptionsScreenState();
}

class _UserOptionsScreenState extends State<UserOptionsScreen> {
  String? _currentUserRole;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final users = await apiService.getUsers();
      final freshUser = users.firstWhere((u) => u.id == widget.user.id);
      if (mounted) {
        setState(() {
          _user = freshUser;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserRole = prefs.getString('role');
    });
  }

  @override
  Widget build(BuildContext context) {
    final userToShow = _user ?? widget.user;
    bool isSuperAdmin = _currentUserRole == 'SUPER_ADMIN';

    // Permission: Super Admin can edit anyone.
    // Others can edit their subordinates (which are already filtered in the previous screen)
    // For safety, we check if the target user is NOT a Super Admin.
    bool canEdit = isSuperAdmin || (userToShow.role != 'SUPER_ADMIN');

    // Format role label (e.g., DEALER -> Dealer)
    String roleLabel = userToShow.role
        .split('_')
        .map((s) =>
            s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1).toLowerCase())
        .join(' ');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('User Options',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildProfileHeader(userToShow),
            const SizedBox(height: 24),
            if (canEdit) ...[
              _buildOption(
                context,
                icon: Icons.edit_rounded,
                label: 'Edit $roleLabel',
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            CreateAdminScreen(user: userToShow)),
                  );
                  if (result == true) Navigator.pop(context, true);
                },
              ),
              const SizedBox(height: 8),
              _buildOption(
                context,
                icon: Icons.account_balance_wallet_rounded,
                label: 'Weekly Credit Limit',
                onTap: () {
                  _showCreditLimitDialog(context, userToShow);
                },
              ),
              const SizedBox(height: 8),
              if (userToShow.role == 'ADMIN' && isSuperAdmin) ...[
                _buildOption(
                  context,
                  icon: Icons.content_cut_rounded,
                  label:
                      'Cut Settings: ${userToShow.cutEnabled ? (userToShow.cutType == "percent" ? "${userToShow.cutValue}% Cut" : "Fixed Count") : "DISABLED"}',
                  onTap: () {
                    _showCutSettingsDialog(context, userToShow);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ],
            _buildOption(
              context,
              icon: Icons.currency_rupee_rounded,
              label: 'Prize & Commission',
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ManagePrizeCommissionScreen(
                          user: _user ?? widget.user)),
                );
                if (result == true) {
                  _loadUserData();
                }
              },
            ),
            const SizedBox(height: 8),
            _buildOption(
              context,
              icon: Icons.percent_rounded,
              label: 'Sales Commission',
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SalesCommissionScreen(user: userToShow)),
                );
                if (result == true) {
                  _loadUserData();
                }
              },
            ),
            const SizedBox(height: 8),
            _buildOption(
              context,
              icon: Icons.format_list_numbered_rounded,
              label: 'User Count Limit',
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          UserGameLimitScreen(user: userToShow)),
                );
                if (result == true) {
                  _loadUserData();
                }
              },
            ),
            const SizedBox(height: 8),
            _buildOption(
              context,
              icon: Icons.settings_suggest_rounded,
              label: 'Price Setting',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          PriceSettingScreen(user: userToShow)),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildOption(
              context,
              icon: Icons.timer_rounded,
              label: 'Game Betting Window',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ManageUserGameTimingsScreen(user: widget.user)),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildOption(
              context,
              icon: Icons.videogame_asset_rounded,
              label: 'Game Permission',
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ManageUserGamePermissionsScreen(user: userToShow)),
                );
                if (result == true) {
                  _loadUserData();
                }
              },
            ),
            const SizedBox(height: 16),
            if (canEdit)
              _buildOption(
                context,
                icon: userToShow.isBlocked
                    ? Icons.lock_open_rounded
                    : Icons.block_flipped,
                label: userToShow.isBlocked
                    ? 'Unblock $roleLabel'
                    : 'Block $roleLabel',
                textColor:
                    userToShow.isBlocked ? Colors.green : Colors.redAccent,
                onTap: () async {
                  final apiService =
                      Provider.of<ApiService>(context, listen: false);
                  try {
                    final success = await apiService.updateUser(userToShow.id, {
                      'is_blocked': !userToShow.isBlocked,
                    });
                    if (success) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(userToShow.isBlocked
                              ? 'User unblocked successfully'
                              : 'User blocked successfully'),
                          backgroundColor: userToShow.isBlocked
                              ? Colors.green
                              : Colors.orange,
                        ));
                      }
                      _loadUserData();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red));
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: const CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, color: Colors.white, size: 32),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            user.username.toUpperCase(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              user.role,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreditLimitDialog(BuildContext context, UserModel userToShow) {
    final TextEditingController _controller =
        TextEditingController(text: userToShow.weeklyCreditLimit.toString());
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Weekly Credit Limit',
                style: TextStyle(fontWeight: FontWeight.bold)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Limit Amount',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6)),
                    prefixIcon: const Icon(Icons.currency_rupee_rounded),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL',
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);
                        final apiService =
                            Provider.of<ApiService>(context, listen: false);
                        try {
                          final double newLimit =
                              double.tryParse(_controller.text) ?? 0.0;
                          final success =
                              await apiService.updateUser(userToShow.id, {
                            'weekly_credit_limit': newLimit,
                          });
                          if (success) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Weekly Credit Limit updated successfully'),
                                    backgroundColor: Colors.green),
                              );
                              Navigator.pop(context);
                            }
                            _loadUserData();
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red),
                            );
                          }
                        } finally {
                          setDialogState(() => isSubmitting = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('UPDATE',
                        style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color textColor = AppColors.primary,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: textColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCutSettingsDialog(BuildContext context, UserModel userToShow) {
    bool cutEnabled = userToShow.cutEnabled;
    String cutType = userToShow.cutType;
    final cutValCtrl = TextEditingController(text: userToShow.cutValue.toString());
    final List<String> categories = [
      'SUPER', 'BOX', 'AB', 'BC', 'AC', 'A', 'B', 'C',
      '3D-10', '3D-25', '3D-30', '3D-60', '4D-110', '4D-55', '4D-20'
    ];
    final Map<String, TextEditingController> catControllers = {
      for (var c in categories)
        c: TextEditingController(text: (userToShow.cutCategoryValues[c] ?? 0).toString())
    };
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Cut Settings - ${userToShow.username.toUpperCase()}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable Cut Option', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Cut bets to Super Admin', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      value: cutEnabled,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setDialogState(() => cutEnabled = val),
                    ),
                    if (cutEnabled) ...[
                      const Divider(),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setDialogState(() => cutType = 'percent'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: cutType == 'percent' ? AppColors.primary : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Percentage (%)',
                                  style: TextStyle(
                                    color: cutType == 'percent' ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () => setDialogState(() => cutType = 'fixed_count'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: cutType == 'fixed_count' ? AppColors.primary : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Fixed Count',
                                  style: TextStyle(
                                    color: cutType == 'fixed_count' ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (cutType == 'percent') ...[
                        const Text('Cut Percentage to Super Admin (%):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: cutValCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            suffixText: '%',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                      ] else ...[
                        const Text('Retained Limit per Category (Excess cuts):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                        const SizedBox(height: 6),
                        ...categories.map((cat) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              SizedBox(width: 75, child: Text(cat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              Expanded(
                                child: SizedBox(
                                  height: 34,
                                  child: TextField(
                                    controller: catControllers[cat],
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: '0 (No cut)',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);
                        final apiService = Provider.of<ApiService>(context, listen: false);
                        final catCuts = {
                          for (var e in catControllers.entries)
                            if ((double.tryParse(e.value.text.trim()) ?? 0.0) > 0)
                              e.key: double.tryParse(e.value.text.trim()) ?? 0.0
                        };
                        final payload = {
                          'cut_enabled': cutEnabled,
                          'cut_type': cutType,
                          'cut_value': double.tryParse(cutValCtrl.text.trim()) ?? 0.0,
                          'cut_category_values': catCuts,
                        };
                        final success = await apiService.updateUser(userToShow.id, payload);
                        if (success) {
                          _loadUserData();
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Cut settings updated successfully'),
                              backgroundColor: Colors.green,
                            ));
                          }
                        } else {
                          setDialogState(() => isSubmitting = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Failed to update cut settings'),
                              backgroundColor: Colors.red,
                            ));
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: isSubmitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('SAVE'),
              ),
            ],
          );
        },
      ),
    );
  }

}
