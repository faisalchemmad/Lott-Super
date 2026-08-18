import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/game_model.dart';
import '../utils/constants.dart';

class ManualForwardingScreen extends StatefulWidget {
  const ManualForwardingScreen({Key? key}) : super(key: key);

  @override
  _ManualForwardingScreenState createState() => _ManualForwardingScreenState();
}

class _ManualForwardingScreenState extends State<ManualForwardingScreen> {
  bool _isLoading = true;
  List<GameModel> _games = [];
  int? _selectedGameId;
  String _selectedState = 'KL';
  List<dynamic> _numbers = [];
  
  Map<String, TextEditingController> _forwardControllers = {};

  final List<String> _betTypes = [
    '', 'A', 'B', 'C', 'AB', 'BC', 'AC', 'SUPER', 'BOX',
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
      setState(() {
        _games = games;
        if (_games.isNotEmpty) _selectedGameId = _games.first.id;
      });
      if (_selectedGameId != null) {
        await _fetchNumbers();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchNumbers() async {
    if (_selectedGameId == null) return;
    final apiService = Provider.of<ApiService>(context, listen: false);
    setState(() => _isLoading = true);
    try {
      final nums = await apiService.getRetainedNumbers(
        gameId: _selectedGameId!, 
        state: _selectedState, 
        type: _selectedType
      );
      setState(() {
        _numbers = nums;
        _forwardControllers.clear();
        for (var n in nums) {
          _forwardControllers['${n['number']}_${n['type']}'] = TextEditingController();
        }
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitForward(dynamic item) async {
    final ctrl = _forwardControllers['${item['number']}_${item['type']}'];
    if (ctrl == null || ctrl.text.isEmpty) return;
    
    int count = int.tryParse(ctrl.text) ?? 0;
    if (count <= 0) return;
    if (count > item['retained_count']) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot forward more than retained count')));
      return;
    }

    final apiService = Provider.of<ApiService>(context, listen: false);
    setState(() => _isLoading = true);
    try {
      await apiService.submitManualForward({
        'game': _selectedGameId,
        'state': _selectedState,
        'items': [
          {'number': item['number'], 'type': item['type'], 'count': count}
        ]
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Forwarded Successfully')));
      await _fetchNumbers();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Forwarding')),
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
                      _fetchNumbers();
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
                      _fetchNumbers();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Filter Type', border: OutlineInputBorder()),
                    value: _selectedType,
                    items: _betTypes.map((t) => DropdownMenuItem(value: t.isEmpty ? null : t, child: Text(t.isEmpty ? 'ALL' : t))).toList(),
                    onChanged: (val) {
                      setState(() => _selectedType = val);
                      _fetchNumbers();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _numbers.isEmpty 
                  ? const Center(child: Text('No bets available to forward'))
                  : ListView.builder(
                      itemCount: _numbers.length,
                      itemBuilder: (context, index) {
                        final item = _numbers[index];
                        final ctrl = _forwardControllers['${item['number']}_${item['type']}'];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Number: ${item['number']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text('Type: ${item['type']}'),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Total DB: ${item['total_count']}'),
                                      Text('Already Fwd: ${item['forwarded_count']}'),
                                      Text('Retained: ${item['retained_count']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: ctrl,
                                    decoration: const InputDecoration(labelText: 'Forward Count', border: OutlineInputBorder()),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: () => _submitForward(item),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                  child: const Text('FORWARD', style: TextStyle(color: Colors.white)),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}
