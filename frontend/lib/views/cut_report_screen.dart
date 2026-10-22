import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../services/api_service.dart';
import '../models/game_model.dart';
import '../models/user_model.dart';

class CutReportScreen extends StatefulWidget {
  final DateTime? initialDate;
  final String? initialGame;

  const CutReportScreen({
    super.key,
    this.initialDate,
    this.initialGame,
  });

  @override
  State<CutReportScreen> createState() => _CutReportScreenState();
}

class _CutReportScreenState extends State<CutReportScreen> {
  late DateTime _fromDate;
  late DateTime _toDate;
  String _selectedGameId = 'ALL';
  String _selectedAdminId = 'ALL';
  bool _isLoading = false;
  Map<String, dynamic>? _reportData;
  List<GameModel> _gamesList = [];
  List<UserModel> _adminsList = [];
  String? _currentUserRole;

  static const Color sapphireColor = Color(0xFF011C6B);
  static const Color accentGreen = Color(0xFF2E7D32);
  static const Color accentRed = Color(0xFFC62828);

  @override
  void initState() {
    super.initState();
    final initDate = widget.initialDate ?? DateTime.now();
    _fromDate = initDate;
    _toDate = initDate;
    _selectedGameId = widget.initialGame ?? 'ALL';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMetadata();
      _loadData();
    });
  }

  Future<void> _loadMetadata() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final profile = await apiService.getProfile();
      final games = await apiService.getGames();
      setState(() {
        _currentUserRole = profile?.role;
        _gamesList = games;
      });

      if (_currentUserRole == 'SUPER_ADMIN') {
        final users = await apiService.getUsers();
        if (mounted) {
          setState(() {
            _adminsList = users.where((u) => u.role == 'ADMIN').toList();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadData() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    setState(() => _isLoading = true);

    final fromStr = DateFormat('yyyy-MM-dd').format(_fromDate);
    final toStr = DateFormat('yyyy-MM-dd').format(_toDate);

    try {
      final res = await apiService.getCutReport(
        fromDate: fromStr,
        toDate: toStr,
        gameId: _selectedGameId == 'ALL' ? null : _selectedGameId,
        adminId: _selectedAdminId == 'ALL' ? null : _selectedAdminId,
      );
      if (mounted) {
        setState(() {
          _reportData = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cut report: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: sapphireColor,
            colorScheme: const ColorScheme.light(primary: sapphireColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _loadData();
    }
  }

  Future<void> _shareSummaryWhatsApp() async {
    if (_reportData == null) return;
    final summary = (_reportData?['summary'] as Map?) ?? {};
    final fStr = DateFormat('dd-MM-yyyy').format(_fromDate);
    final tStr = DateFormat('dd-MM-yyyy').format(_toDate);
    final rangeText = fStr == tStr ? fStr : '$fStr to $tStr';

    final sb = StringBuffer();
    sb.writeln("━━━━━━━━━━━━━━━━━━━━━");
    sb.writeln("📊 *CUT / RETENTION REPORT*");
    sb.writeln("📅 Date: $rangeText");
    sb.writeln("🎮 Game: ${_selectedGameName()}");
    if (_selectedAdminId != 'ALL') {
      final adm = _adminsList.firstWhere(
        (a) => a.id.toString() == _selectedAdminId,
        orElse: () => _adminsList.first,
      );
      sb.writeln("👤 Admin: ${adm.username.toUpperCase()}");
    }
    sb.writeln("━━━━━━━━━━━━━━━━━━━━━");
    sb.writeln("📦 Gross Count: ${_formatNum(summary['total_gross_count'])}");
    sb.writeln("✂️ Cut Count: ${_formatNum(summary['total_cut_count'])}");
    sb.writeln("💰 Cut Sales: ₹${_formatAmount(summary['total_cut_sales'])}");
    sb.writeln("🏆 Cut Winning: ₹${_formatAmount(summary['total_cut_winnings'])}");
    final net = (summary['net_balance'] as num?)?.toDouble() ?? 0.0;
    sb.writeln("💵 Net Balance: ₹${_formatAmount(net)} ${net >= 0 ? '(PROFIT)' : '(LOSS)'}");
    sb.writeln("━━━━━━━━━━━━━━━━━━━━━");

    await Clipboard.setData(ClipboardData(text: sb.toString().trim()));
    await Share.share(sb.toString().trim());
  }

  String _selectedGameName() {
    if (_selectedGameId == 'ALL') return 'ALL GAMES';
    final g = _gamesList.firstWhere(
      (gm) => gm.id.toString() == _selectedGameId,
      orElse: () => _gamesList.first,
    );
    return g.name;
  }

  String _formatNum(dynamic v) {
    if (v == null) return '0';
    final d = (v as num).toDouble();
    return d == d.toInt() ? d.toInt().toString() : d.toStringAsFixed(1);
  }

  static String _formatAmount(dynamic amt) {
    if (amt == null) return '0.00';
    final d = (amt as num).toDouble();
    return d.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final summary = (_reportData?['summary'] as Map?) ?? {};
    final admins = (_reportData?['admins'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          'CUT REPORT',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: sapphireColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share via WhatsApp',
            onPressed: _reportData == null ? null : _shareSummaryWhatsApp,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSummaryCards(summary),
                          const SizedBox(height: 14),
                          _buildCategoryBreakdown(admins),
                          const SizedBox(height: 14),
                          _buildAdminsSection(admins),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final fStr = DateFormat('dd-MM-yyyy').format(_fromDate);
    final tStr = DateFormat('dd-MM-yyyy').format(_toDate);
    final rangeText = fStr == tStr ? fStr : '$fStr - $tStr';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              // Date Range Picker
              Expanded(
                flex: 4,
                child: GestureDetector(
                  onTap: _pickDateRange,
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 16, color: sapphireColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rangeText,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Game Filter
              Expanded(
                flex: 3,
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedGameId,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(value: 'ALL', child: Text('ALL GAMES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                        ..._gamesList.map((g) => DropdownMenuItem(value: g.id.toString(), child: Text(g.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedGameId = val);
                          _loadData();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_currentUserRole == 'SUPER_ADMIN' && _adminsList.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedAdminId,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: 'ALL', child: Text('ALL ADMINS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: sapphireColor))),
                    ..._adminsList.map((a) => DropdownMenuItem(value: a.id.toString(), child: Text(a.username.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedAdminId = val);
                      _loadData();
                    }
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Map summary) {
    final gross = summary['total_gross_count'] ?? 0;
    final cutCnt = summary['total_cut_count'] ?? 0;
    final sales = summary['total_cut_sales'] ?? 0;
    final win = summary['total_cut_winnings'] ?? 0;
    final net = summary['net_balance'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              _buildKpiCard('GROSS COUNT', _formatNum(gross), Colors.blueGrey),
              const SizedBox(width: 8),
              _buildKpiCard('CUT COUNT', _formatNum(cutCnt), sapphireColor),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildKpiCard('CUT SALES', '₹${_formatAmount(sales)}', Colors.blue.shade700),
              const SizedBox(width: 8),
              _buildKpiCard('CUT WINNING', '₹${_formatAmount(win)}', accentRed),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: (net as num) >= 0 ? accentGreen.withOpacity(0.1) : accentRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: (net as num) >= 0 ? accentGreen : accentRed),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'NET BALANCE',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: (net as num) >= 0 ? accentGreen : accentRed,
                  ),
                ),
                Text(
                  '₹${_formatAmount(net)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: (net as num) >= 0 ? accentGreen : accentRed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(List<dynamic> admins) {
    // Aggregate category counts across all selected admins
    Map<String, Map<String, double>> catTotals = {};
    for (var a in admins) {
      final cats = (a['categories'] as Map?) ?? {};
      cats.forEach((k, v) {
        final catKey = k.toString().toUpperCase();
        if (!catTotals.containsKey(catKey)) {
          catTotals[catKey] = {'count': 0.0, 'sales': 0.0, 'winning': 0.0};
        }
        catTotals[catKey]!['count'] = (catTotals[catKey]!['count'] ?? 0.0) + ((v['count'] as num?)?.toDouble() ?? 0.0);
        catTotals[catKey]!['sales'] = (catTotals[catKey]!['sales'] ?? 0.0) + ((v['sales'] as num?)?.toDouble() ?? 0.0);
        catTotals[catKey]!['winning'] = (catTotals[catKey]!['winning'] ?? 0.0) + ((v['winning'] as num?)?.toDouble() ?? 0.0);
      });
    }

    if (catTotals.isEmpty) return const SizedBox.shrink();

    final sortedKeys = catTotals.keys.toList()..sort();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CATEGORY BREAKDOWN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: sapphireColor)),
          const SizedBox(height: 8),
          Table(
            border: TableBorder.all(color: Colors.grey.shade200),
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(3),
              3: FlexColumnWidth(3),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade100),
                children: const [
                  Padding(padding: EdgeInsets.all(6), child: Text('TYPE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(6), child: Text('COUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                  Padding(padding: EdgeInsets.all(6), child: Text('SALES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                  Padding(padding: EdgeInsets.all(6), child: Text('WINNING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                ],
              ),
              ...sortedKeys.map((k) {
                final d = catTotals[k]!;
                return TableRow(
                  children: [
                    Padding(padding: const EdgeInsets.all(6), child: Text(k, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                    Padding(padding: const EdgeInsets.all(6), child: Text(_formatNum(d['count']), style: const TextStyle(fontSize: 11), textAlign: TextAlign.right)),
                    Padding(padding: const EdgeInsets.all(6), child: Text('₹${_formatAmount(d['sales'])}', style: const TextStyle(fontSize: 11), textAlign: TextAlign.right)),
                    Padding(padding: const EdgeInsets.all(6), child: Text('₹${_formatAmount(d['winning'])}', style: TextStyle(fontSize: 11, color: d['winning']! > 0 ? accentRed : Colors.black87), textAlign: TextAlign.right)),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminsSection(List<dynamic> admins) {
    if (admins.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text('No cut data found for selected criteria.', style: TextStyle(color: Colors.grey, fontSize: 13)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ADMIN DETAILS & TOP NUMBERS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: sapphireColor)),
        const SizedBox(height: 8),
        ...admins.map((adm) => _buildAdminCard(adm)),
      ],
    );
  }

  Widget _buildAdminCard(Map adm) {
    final name = (adm['admin_name'] ?? 'ADMIN').toString();
    final gross = adm['total_gross_count'] ?? 0;
    final cutCnt = adm['total_cut_count'] ?? 0;
    final sales = adm['total_cut_sales'] ?? 0;
    final win = adm['total_cut_winning'] ?? 0;
    final net = adm['net_balance'] ?? 0;
    final topNums = (adm['top_numbers'] as List<dynamic>?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: sapphireColor)),
        subtitle: Text(
          'Cut: ${_formatNum(cutCnt)} / ${_formatNum(gross)} | Net: ₹${_formatAmount(net)}',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: (net as num) >= 0 ? accentGreen : accentRed),
        ),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sales: ₹${_formatAmount(sales)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text('Winning: ₹${_formatAmount(win)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentRed)),
            ],
          ),
          if (topNums.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(),
            const Text('TOP RETAINED / CUT NUMBERS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: topNums.take(15).map((tn) {
                final tp = tn['type'];
                final numStr = tn['number'];
                final cnt = tn['count'];
                final winAmt = (tn['winning'] as num?)?.toDouble() ?? 0.0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: winAmt > 0 ? accentRed.withOpacity(0.1) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: winAmt > 0 ? accentRed : Colors.grey.shade300),
                  ),
                  child: Text(
                    '$tp $numStr (${_formatNum(cnt)})',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: winAmt > 0 ? accentRed : Colors.black87,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
