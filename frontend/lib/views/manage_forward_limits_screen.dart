import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/game_model.dart';
import '../utils/constants.dart';

class ManageForwardLimitsScreen extends StatefulWidget {
  const ManageForwardLimitsScreen({Key? key}) : super(key: key);

  @override
  _ManageForwardLimitsScreenState createState() =>
      _ManageForwardLimitsScreenState();
}

class _ManageForwardLimitsScreenState extends State<ManageForwardLimitsScreen> {
  bool _isLoading = true;
  List<GameModel> _games = [];
  int? _selectedGameId;
  String _selectedState = 'KL';
  List<dynamic> _limits = [];
  Map<String, dynamic>? _user;

  final _numberController = TextEditingController();
  final _maxRetainedController = TextEditingController();

  final List<String> _betTypes = [
    'A', 'B', 'C', 'AB', 'BC', 'AC', 'SUPER', 'BOX',
    '3D-10', '3D-25', '3D-30', '3D-60', '4D-110', '4D-55', '4D-20'
  ];
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final games = await apiService.getGames();
      final user = await apiService.getProfile();
      setState(() {
        _games = games;
        if (_games.isNotEmpty) _selectedGameId = _games.first.id;
        if (user != null) {
          _user = {
            'id': user.id,
            'role': user.role,
            'username': user.username
          };
        }
      });
      if (_selectedGameId != null) {
        await _fetchLimits();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchLimits() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final limits = await apiService.getForwardLimits();
      setState(() {
        _limits = limits.where((l) => l['game'] == _selectedGameId && l['state'] == _selectedState).toList();
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _addLimit() async {
    if (_selectedGameId == null || _selectedType == null || _maxRetainedController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill required fields')));
      return;
    }
    final apiService = Provider.of<ApiService>(context, listen: false);
    setState(() => _isLoading = true);
    try {
      await apiService.createForwardLimit({
        'admin': _user?['id'],
        'game': _selectedGameId,
        'state': _selectedState,
        'type': _selectedType,
        'number': _numberController.text.trim(),
        'max_retained_count': int.parse(_maxRetainedController.text.trim())
      });
      _maxRetainedController.clear();
      _numberController.clear();
      _selectedType = null;
      await _fetchLimits();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Limit Added')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteLimit(int id) async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    setState(() => _isLoading = true);
    try {
      await apiService.deleteForwardLimit(id);
      await _fetchLimits();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Limit Deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _games.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Auto Forward Limits')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Game', border: OutlineInputBorder()),
                    value: _selectedGameId,
                    items: _games.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))).toList(),
                    onChanged: (val) {
                      setState(() => _selectedGameId = val);
                      _fetchLimits();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder()),
                    value: _selectedState,
                    items: ['KL', 'TN'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) {
                      setState(() => _selectedState = val!);
                      _fetchLimits();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Type*', border: OutlineInputBorder()),
                    value: _selectedType,
                    items: _betTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) => setState(() => _selectedType = val),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _numberController,
                    decoration: const InputDecoration(labelText: 'Number (Optional)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _maxRetainedController,
                    decoration: const InputDecoration(labelText: 'Retained Limit*', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addLimit,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
                  child: const Text('ADD'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _limits.length,
                    itemBuilder: (context, index) {
                      final item = _limits[index];
                      return Card(
                        child: ListTile(
                          title: Text('Type: ${item['type']} | Limit: ${item['max_retained_count']}'),
                          subtitle: Text('Number: ${item['number']?.isEmpty ?? true ? "ALL" : item['number']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteLimit(item['id']),
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
