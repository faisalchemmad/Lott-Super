import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/number_limit_model.dart';
import '../models/game_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class ManageNumberLimitsScreen extends StatefulWidget {
  const ManageNumberLimitsScreen({super.key});

  @override
  State<ManageNumberLimitsScreen> createState() =>
      _ManageNumberLimitsScreenState();
}

class _ManageNumberLimitsScreenState extends State<ManageNumberLimitsScreen> {
  List<NumberLimitModel> _limits = [];
  List<GameModel> _games = [];
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final results = await Future.wait([
      apiService.getGames(),
      apiService.getNumberLimits(null),
      apiService.getUsers(),
    ]);
    setState(() {
      _games = results[0] as List<GameModel>;
      _limits = results[1] as List<NumberLimitModel>;
      _users = results[2] as List<UserModel>;
      _isLoading = false;
    });
  }

  void _showAddDialog() {
    GameModel? selectedGame = _games.isNotEmpty ? _games[0] : null;
    UserModel? selectedUser = _users.isNotEmpty ? _users[0] : null;
    String selectedType = 'A';
    final numberController = TextEditingController();
    final countController = TextEditingController(text: '50');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add User-wise Number Limit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<UserModel>(
                  value: selectedUser,
                  items: _users
                      .map((u) => DropdownMenuItem(
                          value: u, child: Text('${u.username} (${u.role})')))
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedUser = val),
                  decoration: const InputDecoration(labelText: 'Select User'),
                ),
                DropdownButtonFormField<GameModel>(
                  value: selectedGame,
                  items: _games
                      .map((g) =>
                          DropdownMenuItem(value: g, child: Text(g.name)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedGame = val),
                  decoration: const InputDecoration(labelText: 'Select Game'),
                ),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: ['A', 'B', 'C', 'AB', 'BC', 'AC', 'SUPER', 'BOX']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedType = val!),
                  decoration: const InputDecoration(labelText: 'Bet Type'),
                ),
                TextField(
                  controller: numberController,
                  decoration: const InputDecoration(labelText: 'Number'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: countController,
                  decoration: const InputDecoration(labelText: 'Max Count'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (selectedGame == null ||
                    selectedUser == null ||
                    numberController.text.isEmpty) return;

                // Digit validation
                int reqDigits = 0;
                if (['A', 'B', 'C'].contains(selectedType)) {
                  reqDigits = 1;
                } else if (['AB', 'BC', 'AC'].contains(selectedType)) {
                  reqDigits = 2;
                } else if (['SUPER', 'BOX'].contains(selectedType)) {
                  reqDigits = 3;
                }

                if (numberController.text.length != reqDigits) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Number must be $reqDigits digits')),
                  );
                  return;
                }

                if (int.tryParse(numberController.text) == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a valid single number')),
                  );
                  return;
                }

                final apiService =
                    Provider.of<ApiService>(context, listen: false);
                final success = await apiService.createNumberLimit(
                  selectedGame!.id,
                  selectedUser!.id,
                  numberController.text,
                  selectedType,
                  int.tryParse(countController.text) ?? 50,
                );
                if (success) {
                  Navigator.pop(context);
                  _loadData();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Special Number Limits')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _limits.isEmpty
              ? const Center(child: Text('No custom number limits set'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _limits.length,
                  itemBuilder: (context, index) {
                    final limit = _limits[index];
                    return Card(
                      child: ListTile(
                        title: Text('Number: ${limit.number} (${limit.type})'),
                        subtitle: Text(
                            'User: ${limit.userUsername}\nGame: ${limit.gameName}\nMax Bets: ${limit.maxCount}'),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final apiService =
                                Provider.of<ApiService>(context, listen: false);
                            if (await apiService.deleteNumberLimit(limit.id)) {
                              _loadData();
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
