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
              const SizedBox(height: 12),
              _buildOption(
                context,
                icon: Icons.account_balance_wallet_rounded,
                label: 'Weekly Credit Limit',
                onTap: () {
                  _showCreditLimitDialog(context, userToShow);
                },
              ),
              const SizedBox(height: 12),
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
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            _buildOption(
              context,
              icon: Icons.format_list_numbered_rounded,
              label: 'User Count Limit',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          UserGameLimitScreen(user: widget.user)),
                );
              },
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
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
            const SizedBox(height: 24),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: const CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.username.toUpperCase(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
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
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Limit Amount',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
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
                          final success = await apiService.updateUser(userToShow.id, {
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
                          } else {
                            throw Exception('Failed to update limit');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red));
                          }
                        } finally {
                          if (context.mounted) {
                            setDialogState(() => isSubmitting = false);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: textColor, size: 24),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
