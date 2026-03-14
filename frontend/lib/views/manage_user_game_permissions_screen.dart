import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class ManageUserGamePermissionsScreen extends StatefulWidget {
  final UserModel user;
  const ManageUserGamePermissionsScreen({super.key, required this.user});

  @override
  State<ManageUserGamePermissionsScreen> createState() => _ManageUserGamePermissionsScreenState();
}

class _ManageUserGamePermissionsScreenState extends State<ManageUserGamePermissionsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<dynamic> _allGames = [];
  Set<int> _allowedGameIds = {};

  @override
  void initState() {
    super.initState();
    _allowedGameIds = Set.from(widget.user.allowedGames);
    _loadGames();
  }

  Future<void> _loadGames() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final games = await apiService.getGames();
      setState(() {
        _allGames = games;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading games: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _savePermissions() async {
    setState(() => _isSaving = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    
    try {
      final success = await apiService.updateUser(widget.user.id, {
        'allowed_games': _allowedGameIds.toList(),
      });
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Game permissions updated successfully!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Failed to update game permissions');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Game Permissions', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  color: AppColors.primary,
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Allowed Games',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select which games ${widget.user.username.toUpperCase()} is allowed to play.',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _allGames.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final game = _allGames[index];
                      final isAllowed = _allowedGameIds.contains(game.id);
                      
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: CheckboxListTile(
                          title: Text(game.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Text('ID: ${game.id}'),
                          value: isAllowed,
                          activeColor: AppColors.primary,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _allowedGameIds.add(game.id);
                              } else {
                                _allowedGameIds.remove(game.id);
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _savePermissions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save Permissions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
