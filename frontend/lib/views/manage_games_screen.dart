import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/game_model.dart';
import '../utils/constants.dart';

class ManageGamesScreen extends StatefulWidget {
  const ManageGamesScreen({super.key});

  @override
  State<ManageGamesScreen> createState() => _ManageGamesScreenState();
}

class _ManageGamesScreenState extends State<ManageGamesScreen> {
  List<GameModel> _games = [];
  bool _isLoading = true;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadGames();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userRole = prefs.getString('role'));
  }

  bool get _canManageGames => _userRole == 'SUPER_ADMIN';

  Future<void> _loadGames() async {
    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final games = await apiService.getGames();
    setState(() {
      _games = games;
      _isLoading = false;
    });
  }

  void _showGameDialog([GameModel? game]) async {
    final nameController = TextEditingController(text: game?.name ?? '');

    TimeOfDay drawTime = const TimeOfDay(hour: 0, minute: 0);
    TimeOfDay startTime = const TimeOfDay(hour: 0, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 23, minute: 59);
    TimeOfDay deadlineTime = const TimeOfDay(hour: 23, minute: 59);
    bool canEditDelete = game?.canEditDelete ?? true;
    String selectedColor = game?.color ?? '#2C3E50';

    if (game != null) {
      try {
        final dParts = game.time.split(':');
        drawTime =
            TimeOfDay(hour: int.parse(dParts[0]), minute: int.parse(dParts[1]));

        final sParts = game.startTime.split(':');
        startTime =
            TimeOfDay(hour: int.parse(sParts[0]), minute: int.parse(sParts[1]));

        final eParts = game.endTime.split(':');
        endTime =
            TimeOfDay(hour: int.parse(eParts[0]), minute: int.parse(eParts[1]));

        final dlParts = game.editDeleteLimitTime.split(':');
        deadlineTime = TimeOfDay(
            hour: int.parse(dlParts[0]), minute: int.parse(dlParts[1]));
      } catch (_) {}
    }

    String formatTime(TimeOfDay t) =>
        "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(game == null ? 'Add Game' : 'Edit Game'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                      labelText: 'Game Name (e.g. 1PM DRAW)'),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Draw Time'),
                  subtitle: Text(drawTime.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(
                        context: context, initialTime: drawTime);
                    if (picked != null) setDialogState(() => drawTime = picked);
                  },
                ),
                ListTile(
                  title: const Text('Betting Start'),
                  subtitle: Text(startTime.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(
                        context: context, initialTime: startTime);
                    if (picked != null)
                      setDialogState(() => startTime = picked);
                  },
                ),
                ListTile(
                  title: const Text('Betting End'),
                  subtitle: Text(endTime.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(
                        context: context, initialTime: endTime);
                    if (picked != null) setDialogState(() => endTime = picked);
                  },
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Allow Edit/Delete'),
                  subtitle: const Text('Enable invoice changes for this game'),
                  value: canEditDelete,
                  onChanged: (val) => setDialogState(() => canEditDelete = val),
                ),
                ListTile(
                  title: const Text('Edit/Delete Deadline'),
                  subtitle: Text(deadlineTime.format(context)),
                  trailing: const Icon(Icons.timer_outlined),
                  onTap: () async {
                    final picked = await showTimePicker(
                        context: context, initialTime: deadlineTime);
                    if (picked != null)
                      setDialogState(() => deadlineTime = picked);
                  },
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Betting Screen Color',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: [
                    '#9C212C',
                    '#2E7D32',
                    '#1565C0',
                    '#F9A825',
                    '#6A1B9A',
                    '#2C3E50',
                    '#E91E63'
                  ]
                      .map((c) => GestureDetector(
                            onTap: () =>
                                setDialogState(() => selectedColor = c),
                            child: Container(
                              width: 35,
                              height: 35,
                              decoration: BoxDecoration(
                                color: Color(
                                    int.parse(c.replaceFirst('#', '0xFF'))),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selectedColor == c
                                      ? Colors.black
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: selectedColor == c
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 20)
                                  : null,
                            ),
                          ))
                      .toList(),
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
                final apiService =
                    Provider.of<ApiService>(context, listen: false);

                bool success;
                if (game == null) {
                  success = await apiService.createGame(
                    nameController.text,
                    formatTime(drawTime),
                    startTime: formatTime(startTime),
                    endTime: formatTime(endTime),
                    color: selectedColor,
                    canEditDelete: canEditDelete,
                    deadlineTime: formatTime(deadlineTime),
                  );
                } else {
                  try {
                    await apiService.updateGame(game.id, {
                      'name': nameController.text,
                      'time': formatTime(drawTime),
                      'start_time': formatTime(startTime),
                      'end_time': formatTime(endTime),
                      'color': selectedColor,
                      'can_edit_delete': canEditDelete,
                      'edit_delete_limit_time': formatTime(deadlineTime),
                    });
                    success = true;
                  } catch (e) {
                    success = false;
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                }

                if (success) {
                  Navigator.pop(context);
                  _loadGames();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(GameModel game) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Game'),
        content: Text('Are you sure you want to delete ${game.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              final apiService =
                  Provider.of<ApiService>(context, listen: false);
              final success = await apiService.deleteGame(game.id);
              if (success) {
                if (mounted) {
                  Navigator.pop(context);
                  _loadGames();
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Game deleted')));
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Games')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _games.length,
              itemBuilder: (context, index) {
                final game = _games[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(
                          int.parse(game.color.replaceFirst('#', '0xFF'))),
                      radius: 12,
                    ),
                    title: Text(game.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        'Draw: ${game.time} | Window: ${game.startTime} - ${game.endTime}'),
                    trailing: _canManageGames
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: AppColors.primary),
                                onPressed: () => _showGameDialog(game),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDelete(game),
                              ),
                            ],
                          )
                        : null,
                  ),
                );
              },
            ),
      floatingActionButton: _canManageGames
          ? FloatingActionButton(
              onPressed: () => _showGameDialog(),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
