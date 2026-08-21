import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/game_model.dart';
import '../utils/constants.dart';

class ForwardNetReportScreen extends StatefulWidget {
  const ForwardNetReportScreen({super.key});

  @override
  State<ForwardNetReportScreen> createState() => _ForwardNetReportScreenState();
}

class _ForwardNetReportScreenState extends State<ForwardNetReportScreen> {
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  int? _selectedGameId;
  List<GameModel> _games = [];
  bool _isLoadingGames = true;
  bool _isGenerating = false;
  List<dynamic> _reportData = [];

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
      final data = await apiService.getForwardNetReport(
        fromDate: DateFormat('yyyy-MM-dd').format(_fromDate),
        toDate: DateFormat('yyyy-MM-dd').format(_toDate),
        gameId: _selectedGameId,
      );
      
      setState(() {
        _reportData = data;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _reportData = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load report: $e')),
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
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Select Game (Optional)',
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

  Widget _buildReportTable() {
    if (_reportData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No data found for the selected filters', style: TextStyle(fontSize: 16)),
        ),
      );
    }

    double totalPurchase = 0;
    double totalFwdWinComm = 0;
    double totalBalance = 0;

    for (var row in _reportData) {
      totalPurchase += (row['purchase'] ?? 0).toDouble();
      totalFwdWinComm += (row['fwd_winning_commi'] ?? 0).toDouble();
      totalBalance += (row['balance'] ?? 0).toDouble();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                Expanded(flex: 3, child: Text('Purch.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.right)),
                Expanded(flex: 4, child: Text('Win+Com', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.right)),
                Expanded(flex: 3, child: Text('Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.right)),
              ],
            ),
          ),
          // Data Rows
          ..._reportData.map((row) {
            final balance = (row['balance'] ?? 0).toDouble();
            final dateStr = row['date'].toString();
            // Try to extract DD-MM from YYYY-MM-DD
            String dateShort = dateStr;
            if (dateStr.length >= 10) {
              final parts = dateStr.split('-');
              if (parts.length == 3) {
                dateShort = '${parts[2]}-${parts[1]}';
              }
            }
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(dateShort, style: const TextStyle(fontSize: 11))),
                  Expanded(flex: 3, child: Text((row['purchase'] ?? 0).toStringAsFixed(1), style: const TextStyle(fontSize: 11), textAlign: TextAlign.right)),
                  Expanded(flex: 4, child: Text((row['fwd_winning_commi'] ?? 0).toStringAsFixed(1), style: const TextStyle(fontSize: 11), textAlign: TextAlign.right)),
                  Expanded(
                    flex: 3, 
                    child: Text(
                      balance.toStringAsFixed(1), 
                      style: TextStyle(
                        fontSize: 11,
                        color: balance < 0 ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ), 
                      textAlign: TextAlign.right
                    )
                  ),
                ],
              ),
            );
          }).toList(),
          // Total Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Expanded(flex: 3, child: Text('TOT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                Expanded(flex: 3, child: Text(totalPurchase.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.right)),
                Expanded(flex: 4, child: Text(totalFwdWinComm.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.right)),
                Expanded(
                  flex: 3, 
                  child: Text(
                    totalBalance.toStringAsFixed(1), 
                    style: TextStyle(
                      fontSize: 11,
                      color: totalBalance < 0 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ), 
                    textAlign: TextAlign.right
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forward Net Report', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isGenerating
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: [
                      _buildReportTable(),
                      const SizedBox(height: 20),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
