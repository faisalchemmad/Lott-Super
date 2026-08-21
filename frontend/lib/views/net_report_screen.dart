import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
    bool isDesktop = defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;

    Widget content = Column(
      children: [
        if (!isDesktop) _buildFilterSection(isDesktop),
        _buildPeriodView(isDesktop),
        if (_breadcrumbStack.isNotEmpty) _buildBreadcrumbs(isDesktop),
        _buildTableHeader(isDesktop),
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
                          _buildReportRow(_reportData[index], isDesktop),
                    ),
        ),
        if (_reportData.isNotEmpty) _buildSummaryFooter(isDesktop),
      ],
    );

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
          title: const Text('Net Report',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18)),
          backgroundColor: AppColors.primary,
          centerTitle: !isDesktop,
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
        body: isDesktop
            ? Row(
                children: [
                  SizedBox(
                    width: 300,
                    child: SingleChildScrollView(child: _buildFilterSection(isDesktop)),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: content),
                ],
              )
            : content,
      ),
    );
  }

  Widget _buildPeriodView(bool isDesktop) {
    final fmt = DateFormat('dd MMM yyyy');
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: isDesktop ? 24 : 16),
      color: Colors.white,
      child: Row(
        children: [
          Icon(Icons.date_range_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            'REPORT PERIOD: ',
            style: TextStyle(
                fontSize: isDesktop ? 11 : 9, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          Text(
            '${fmt.format(_fromDate)} - ${fmt.format(_toDate)}',
            style: TextStyle(
                fontSize: isDesktop ? 12 : 10, fontWeight: FontWeight.w900, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        border: const Border(bottom: BorderSide(color: Color(0xFFDDDDDD))),
      ),
      child: Row(
        children: [
          Expanded(
              flex: isDesktop ? 5 : 3,
              child: Text('USER',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: isDesktop ? 13 : 11))),
          Expanded(
              flex: 2,
              child: Text('SALES',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: isDesktop ? 13 : 11))),
          Expanded(
              flex: 2,
              child: Text('WIN/CO',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: isDesktop ? 13 : 11))),
          Expanded(
              flex: 2,
              child: Text('BALANCE',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: isDesktop ? 13 : 11))),
        ],
      ),
    );
  }

  Widget _buildReportRow(dynamic item, bool isDesktop) {
    bool isDrillable = item['is_drillable'] ?? false;
    double balance = (item['balance'] ?? 0).toDouble();

    return InkWell(
      onTap:
          isDrillable ? () => _generateReport(userId: item['user_id']) : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: isDesktop ? 18 : 14),
        child: Row(
          children: [
            Expanded(
              flex: isDesktop ? 5 : 3,
              child: Text(
                '${item['user']}${isDrillable ? ' >' : ''}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isDesktop ? 14 : 12,
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
                    TextStyle(fontSize: isDesktop ? 14 : 12, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '₹${(item['win_co'] ?? 0).toStringAsFixed(0)}',
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: Colors.red,
                    fontSize: isDesktop ? 14 : 12,
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
                  fontSize: isDesktop ? 14 : 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbs(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        fontSize: isDesktop ? 13 : 12),
                  ),
                ),
                if (!isLast)
                  const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFilterSection(bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) ...[
            const Text('FILTERS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 16),
          ],
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: isDesktop ? 260 : 110,
                child: _buildDateTile('FROM', _fromDate, () => _selectDate(true), isDesktop),
              ),
              SizedBox(
                width: isDesktop ? 260 : 110,
                child: _buildDateTile('TO', _toDate, () => _selectDate(false), isDesktop),
              ),
              if (!_isLoadingGames)
                Container(
                  width: isDesktop ? 260 : null,
                  height: isDesktop ? 50 : 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      isExpanded: true,
                      value: _selectedGameId,
                      style: TextStyle(
                          fontSize: isDesktop ? 13 : 11, color: Colors.black87),
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateTile(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Text(
          // ignore: undefined_function
          DateFormat('dd/MM/yyyy').format(date),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildSummaryFooter(bool isDesktop) {
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
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 30 : 16, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!, width: 2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _summaryItem('TOTAL SALES', totalGross, Colors.blueGrey, isDesktop),
          _summaryItem('TOTAL WIN/CO', totalWinCo, Colors.red, isDesktop),
          _summaryItem('NET BALANCE', totalBalance,
              totalBalance >= 0 ? Colors.green : Colors.red, isDesktop, isMain: true),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, double value, Color color, bool isDesktop, {bool isMain = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: isDesktop ? 11 : 8,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold)),
        Text('₹${value.toStringAsFixed(0)}',
            style: TextStyle(
                fontSize: isMain ? (isDesktop ? 20 : 14) : (isDesktop ? 16 : 12), 
                fontWeight: FontWeight.w900, 
                color: color)),
      ],
    );
  }
}
