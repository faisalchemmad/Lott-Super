import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/game_model.dart';
import '../utils/constants.dart';

class ForwardPurchaseReportScreen extends StatefulWidget {
  const ForwardPurchaseReportScreen({super.key});

  @override
  State<ForwardPurchaseReportScreen> createState() => _ForwardPurchaseReportScreenState();
}

class _ForwardPurchaseReportScreenState extends State<ForwardPurchaseReportScreen> {
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  int? _selectedGameId;
  String? _searchNumber;
  List<GameModel> _games = [];
  bool _isLoadingGames = true;
  bool _isGenerating = false;
  List<dynamic> _invoices = [];
  
  double _totalSales = 0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchGames();
    _generateReport();
  }

  Future<void> _fetchGames() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final games = await apiService.getGames();
      setState(() {
        _games = games;
        _isLoadingGames = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingGames = false;
      });
    }
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
    });
    
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final data = await apiService.getForwardPurchaseReport(
        fromDate: DateFormat('yyyy-MM-dd').format(_fromDate),
        toDate: DateFormat('yyyy-MM-dd').format(_toDate),
        gameId: _selectedGameId,
        number: _searchNumber,
      );
      
      setState(() {
        _invoices = data['invoices'] ?? [];
        _totalSales = (data['sales'] ?? 0).toDouble();
        _totalCount = (data['count'] ?? 0).toInt();
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _invoices = [];
        _totalSales = 0;
        _totalCount = 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load report: $e')),
        );
      }
    }
  }
  
  Future<void> _deleteBet(int id, int itemIndex, int invoiceIndex) async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final success = await apiService.deleteForwardedBet(id);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item deleted successfully'), backgroundColor: Colors.green),
          );
        }
        _generateReport(); // Refresh the list to update totals
      } else {
        throw Exception('Failed to delete');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting item: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildFilters() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _fromDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _fromDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'From Date',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(DateFormat('dd-MM-yyyy').format(_fromDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _toDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _toDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'To Date',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(DateFormat('dd-MM-yyyy').format(_toDate)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Select Game',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    value: _selectedGameId,
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('All Games'),
                      ),
                      ..._games.map((game) {
                        return DropdownMenuItem<int>(
                          value: game.id,
                          child: Text(game.name),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedGameId = value);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Number',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      _searchNumber = val;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _generateReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('GENERATE', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_invoices.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No forwarded items found.', style: TextStyle(fontSize: 16)),
        ),
      );
    }
    
    // Flatten invoices to just a list of items for easier swiping
    List<Map<String, dynamic>> flatItems = [];
    for (int i = 0; i < _invoices.length; i++) {
      var inv = _invoices[i];
      var items = inv['items'] as List<dynamic>;
      for (int j = 0; j < items.length; j++) {
        var item = items[j];
        flatItems.add({
          'id': item['id'],
          'type': item['type'],
          'number': item['number'],
          'count': item['count'],
          'amount': item['amount'],
          'total': item['total'],
          'date': inv['created_at'],
          'game': inv['game__name'],
          'invIndex': i,
          'itemIndex': j
        });
      }
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey.shade200,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Count: $_totalCount', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Total Amt: ${_totalSales.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: flatItems.length,
            itemBuilder: (context, index) {
              final item = flatItems[index];
              final dateStr = item['date'] != null ? DateFormat('dd/MM HH:mm').format(DateTime.parse(item['date'])) : '';
              
              return Dismissible(
                key: Key(item['id'].toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Confirm Delete"),
                        content: const Text("Are you sure you want to delete this forwarded bet?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("CANCEL"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("DELETE", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) {
                  _deleteBet(item['id'], item['itemIndex'], item['invIndex']);
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(item['type'].toString(), style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                    title: Text('${item['game']} - Number: ${item['number']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Count: ${item["count"]} x ${item["amount"]} = ${item["total"]} \n$dateStr'),
                    trailing: const Icon(Icons.swipe_left, color: Colors.grey, size: 16),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forwarded Purchase Report', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isGenerating
                ? const Center(child: CircularProgressIndicator())
                : _buildList(),
          ),
        ],
      ),
    );
  }
}
