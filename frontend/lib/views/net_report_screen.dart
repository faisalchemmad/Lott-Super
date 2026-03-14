import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/game_model.dart';
import '../utils/constants.dart';

class NetReportScreen extends StatefulWidget {
  const NetReportScreen({super.key});

  @override
  State<NetReportScreen> createState() => _NetReportScreenState();
}

class _NetReportScreenState extends State<NetReportScreen> {
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  int? _selectedGameId;
  List<GameModel> _games = [];
  bool _isLoadingGames = true;
  bool _isGenerating = false;
  List<dynamic> _reportData = [];

  final List<Map<String, dynamic>> _breadcrumbStack = [];

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
      setState(() => _isLoadingGames = false);
    }
  }

  Future<void> _selectDate(bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isFrom)
          _fromDate = picked;
        else
          _toDate = picked;
      });
      _generateReport(
          userId:
              _breadcrumbStack.isNotEmpty ? _breadcrumbStack.last['id'] : null);
    }
  }

  Future<void> _generateReport({int? userId}) async {
    setState(() => _isGenerating = true);
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final response = await apiService.getNetReport(
        fromDate: DateFormat('yyyy-MM-dd').format(_fromDate),
        toDate: DateFormat('yyyy-MM-dd').format(_toDate),
        gameId: _selectedGameId,
        userId: userId,
      );

      setState(() {
        _reportData = response['data'] ?? [];
        _isGenerating = false;

        final bc = response['breadcrumb'];
        if (bc != null && bc['id'] != null) {
          int existingIdx = _breadcrumbStack
              .indexWhere((element) => element['id'] == bc['id']);
          if (existingIdx != -1) {
            _breadcrumbStack.removeRange(
                existingIdx + 1, _breadcrumbStack.length);
          } else {
            _breadcrumbStack
                .add({'id': bc['id'], 'name': bc['name'], 'role': bc['role']});
          }
        }
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _popBreadcrumb() {
    if (_breadcrumbStack.length > 1) {
      _breadcrumbStack.removeLast();
      _generateReport(userId: _breadcrumbStack.last['id']);
    } else if (_breadcrumbStack.length == 1) {
      _breadcrumbStack.clear();
      _generateReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_breadcrumbStack.length <= 1) {
          return true;
        }
        _popBreadcrumb();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Daily Report',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18)),
          backgroundColor: AppColors.primary,
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (_breadcrumbStack.length <= 1) {
                Navigator.pop(context);
              } else {
                _popBreadcrumb();
              }
            },
          ),
        ),
        body: Column(
          children: [
            _buildFilterSection(),
            _buildPeriodView(),
            if (_breadcrumbStack.isNotEmpty) _buildBreadcrumbs(),
            _buildTableHeader(),
            Expanded(
              child: _isGenerating
                  ? const Center(child: CircularProgressIndicator())
                  : _reportData.isEmpty
                      ? const Center(child: Text('No data found'))
                      : ListView.separated(
                          itemCount: _reportData.length,
                          separatorBuilder: (c, i) => const Divider(
                              height: 1, color: Color(0xFFEEEEEE)),
                          itemBuilder: (context, index) =>
                              _buildReportRow(_reportData[index]),
                        ),
            ),
            if (_reportData.isNotEmpty) _buildSummaryFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodView() {
    final fmt = DateFormat('dd MMM yyyy');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: Colors.white,
      child: Row(
        children: [
          Icon(Icons.date_range_rounded, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          const Text(
            'REPORT PERIOD: ',
            style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          Text(
            '${fmt.format(_fromDate)} - ${fmt.format(_toDate)}',
            style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        border: const Border(bottom: BorderSide(color: Color(0xFFDDDDDD))),
      ),
      child: const Row(
        children: [
          Expanded(
              flex: 3,
              child: Text('USER',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(
              flex: 2,
              child: Text('SALES',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(
              flex: 2,
              child: Text('WIN/CO',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(
              flex: 2,
              child: Text('BALANCE',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildReportRow(dynamic item) {
    bool isDrillable = item['is_drillable'] ?? false;
    double balance = (item['balance'] ?? 0).toDouble();

    return InkWell(
      onTap:
          isDrillable ? () => _generateReport(userId: item['user_id']) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                '${item['user']}${isDrillable ? ' >' : ''}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isDrillable ? Colors.blue : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '₹${(item['gross_sale'] ?? 0).toStringAsFixed(0)}',
                textAlign: TextAlign.right,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '₹${(item['win_co'] ?? 0).toStringAsFixed(0)}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '₹${balance.toStringAsFixed(0)}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: balance >= 0 ? const Color(0xFF10B981) : Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _breadcrumbStack.map((bc) {
            int idx = _breadcrumbStack.indexOf(bc);
            bool isLast = idx == _breadcrumbStack.length - 1;
            return Row(
              children: [
                GestureDetector(
                  onTap:
                      isLast ? null : () => _generateReport(userId: bc['id']),
                  child: Text(
                    bc['name'],
                    style: TextStyle(
                        fontWeight:
                            isLast ? FontWeight.bold : FontWeight.normal,
                        color: isLast ? Colors.black : Colors.blue,
                        fontSize: 12),
                  ),
                ),
                if (!isLast)
                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _buildDateTile(
                      'FROM', _fromDate, () => _selectDate(true))),
              const SizedBox(width: 6),
              Expanded(
                  child:
                      _buildDateTile('TO', _toDate, () => _selectDate(false))),
              const SizedBox(width: 6),
              if (!_isLoadingGames)
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        isExpanded: true,
                        value: _selectedGameId,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black87),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('ALL GAMES')),
                          ..._games.map((g) => DropdownMenuItem(
                              value: g.id, child: Text(g.name))),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedGameId = val);
                          _generateReport(
                              userId: _breadcrumbStack.isNotEmpty
                                  ? _breadcrumbStack.last['id']
                                  : null);
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateTile(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 8,
                    fontWeight: FontWeight.bold)),
            Text(DateFormat('dd/MM/yy').format(date),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryFooter() {
    double totalGross =
        _reportData.fold(0.0, (sum, item) => sum + (item['gross_sale'] ?? 0));
    double totalWinCo =
        _reportData.fold(0.0, (sum, item) => sum + (item['win_co'] ?? 0));
    double totalNet =
        _reportData.fold(0.0, (sum, item) => sum + (item['all_sale'] ?? 0));
    double totalWin =
        _reportData.fold(0.0, (sum, item) => sum + (item['winning'] ?? 0));
    double totalBalance = totalNet - totalWin;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryItem('TOTAL SALES', totalGross, Colors.blueGrey),
              _summaryItem('TOTAL WIN/CO', totalWinCo, Colors.red),
              _summaryItem('BALANCE', totalBalance,
                  totalBalance >= 0 ? Colors.green : Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 8,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold)),
        Text('₹${value.toStringAsFixed(0)}',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}
