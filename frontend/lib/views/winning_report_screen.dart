import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/api_service.dart';
import '../models/game_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class WinningReportScreen extends StatefulWidget {
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final int? initialGameId;
  final int? initialAgentId;
  final bool initialAgentRate;
  final String? initialNumber;

  const WinningReportScreen({
    super.key,
    this.initialFromDate,
    this.initialToDate,
    this.initialGameId,
    this.initialAgentId,
    this.initialAgentRate = false,
    this.initialNumber,
  });

  @override
  State<WinningReportScreen> createState() => _WinningReportScreenState();
}

class _WinningReportScreenState extends State<WinningReportScreen> {
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  List<GameModel> _games = [];
  GameModel? _selectedGame;
  List<UserModel> _agents = [];
  UserModel? _selectedAgent;
  List<dynamic> _winners = [];
  List<dynamic> _userSummary = [];
  double _totalAmount = 0.0;
  double _totalCommission = 0.0;
  bool _isLoading = false;
  bool _agentRate = false;
  UserModel? _currentUser;
  String? _userRole;
  final TextEditingController _numberController = TextEditingController();
  List<Map<String, dynamic>> _groupedWinners = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialFromDate != null) _fromDate = widget.initialFromDate!;
    if (widget.initialToDate != null) _toDate = widget.initialToDate!;
    _agentRate = widget.initialAgentRate;
    if (widget.initialNumber != null)
      _numberController.text = widget.initialNumber!;

    _loadFilters().then((_) {
      if (widget.initialGameId != null) {
        _selectedGame = _games.firstWhere((g) => g.id == widget.initialGameId);
      }
      if (widget.initialAgentId != null) {
        _selectedAgent =
            _agents.firstWhere((a) => a.id == widget.initialAgentId);
      }
      _fetchReport();
    });

    // Only show auto filter if NOT coming from filter page
    if (widget.initialFromDate == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showFilterSheet());
    }
  }

  Future<void> _loadFilters() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final games = await apiService.getGames();
    final users = await apiService.getUsers();
    final profile = await apiService.getProfile();
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');
    setState(() {
      _games = games;
      _agents = users;
      _currentUser = profile;
      _userRole = role;

      if (role == 'SUB_DEALER' && profile != null) {
        _selectedAgent = profile;
      }
    });
  }

  Future<void> _fetchReport() async {
    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final data = await apiService.getWinningReport(
        fromDate: DateFormat('yyyy-MM-dd').format(_fromDate),
        toDate: DateFormat('yyyy-MM-dd').format(_toDate),
        gameId: _selectedGame?.id,
        userId: _selectedAgent?.id,
        number:
            _numberController.text.isNotEmpty ? _numberController.text : null,
        adminRate: _agentRate,
      );
      setState(() {
        _winners = data['winners'] ?? [];
        _userSummary = data['user_summary'] ?? [];
        _totalAmount =
            (data['total_winning_amount'] as num?)?.toDouble() ?? 0.0;
        _totalCommission =
            (data['total_winning_commission'] as num?)?.toDouble() ?? 0.0;
        _processWinners();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _processWinners() {
    Map<String, Map<String, dynamic>> groups = {};

    for (var win in _winners) {
      String prizeType = (win['winning_prize_type'] ?? 'WIN').toUpperCase();
      String number = win['number'] ?? 'N/A';
      int gameId = win['game'] ?? 0;

      // Grouping key: (Game + Category + Number)
      String key = "${gameId}_${prizeType}_$number";

      if (!groups.containsKey(key)) {
        groups[key] = {
          'game_name': win['game_name'],
          'number': number,
          'winning_prize_type': prizeType,
          'type': win['type'],
          'total_count': 0,
          'total_prize': 0.0,
          'total_comm': 0.0,
          'users': <dynamic>[],
        };
      }

      var g = groups[key]!;
      g['total_count'] += (win['count'] as num?)?.toInt() ?? 0;
      g['total_prize'] += (win['winning_amount'] as num?)?.toDouble() ?? 0.0;
      g['total_comm'] += (win['winning_commission'] as num?)?.toDouble() ?? 0.0;
      g['users'].add(win);
    }

    _groupedWinners = groups.values.toList();
    // Sort logic: 1st Prize at top, then by number
    // Sort logic
    _groupedWinners.sort((a, b) {
      String ptA = a['winning_prize_type'].toUpperCase();
      String ptB = b['winning_prize_type'].toUpperCase();

      int getPriority(String pt) {
        if (pt == 'BOX (1ST PRIZE) EXACT') return 1;
        if (pt == 'BOX2 (1ND PRIZE)') return 2;
        if (pt.contains('1ST')) return 3;
        if (pt.contains('2ND')) return 4;
        if (pt.contains('3RD')) return 5;
        if (pt.contains('4TH')) return 6;
        if (pt.contains('5TH')) return 7;
        if (pt.contains('COMPLIMENT')) return 8;
        return 10;
      }

      int pA = getPriority(ptA);
      int pB = getPriority(ptB);

      if (pA != pB) return pA.compareTo(pB);
      return ptA.compareTo(ptB);
    });
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _sharePDF() async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('WINNING REPORT',
                          style: pw.TextStyle(font: boldFont, fontSize: 20)),
                      pw.Text(
                          'Print Time: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}',
                          style: pw.TextStyle(font: font, fontSize: 10)),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Game: ${_selectedGame?.name ?? 'ALL GAMES'}',
                          style: pw.TextStyle(font: boldFont, fontSize: 12)),
                      pw.Text(
                          'Period: ${DateFormat('dd/MM/yyyy').format(_fromDate)} - ${DateFormat('dd/MM/yyyy').format(_toDate)}',
                          style: pw.TextStyle(font: font, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey300),
              headerStyle: pw.TextStyle(font: boldFont, fontSize: 10),
              cellStyle: pw.TextStyle(font: font, fontSize: 9),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey100),
              headers: [
                'User',
                'Game Type',
                'Num',
                'Qty',
                'Prize+Commission',
                'Total'
              ],
              data: _winners.map((win) {
                double amount =
                    (win['winning_amount'] as num?)?.toDouble() ?? 0.0;
                double commission =
                    (win['winning_commission'] as num?)?.toDouble() ?? 0.0;
                int count = (win['count'] as num?)?.toInt() ?? 1;
                double totalRow = amount + commission;
                double unitPrizeComm = count > 0 ? totalRow / count : 0.0;

                return [
                  (win['user_username'] ?? 'N/A').toString().toUpperCase(),
                  (win['winning_prize_type'] ?? 'WIN').toString().toUpperCase(),
                  (win['number'] ?? '').toString(),
                  count.toString(),
                  unitPrizeComm.toStringAsFixed(0),
                  totalRow.toStringAsFixed(0),
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Total Winners: ${_winners.length}',
                        style: pw.TextStyle(font: font, fontSize: 11)),
                    pw.Text(
                        'Total Amount: ₹${(_totalAmount + _totalCommission).toStringAsFixed(2)}',
                        style: pw.TextStyle(font: boldFont, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(
        bytes: await pdf.save(), filename: 'winning_report.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Winning Report',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: Colors.white,
                  fontSize: 18)),
          centerTitle: true,
          backgroundColor: AppColors.primary,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
              onPressed: _sharePDF,
              tooltip: 'Share PDF',
            ),
            IconButton(
              icon: const Icon(Icons.tune_rounded, color: Colors.white),
              onPressed: _showFilterSheet,
              tooltip: 'Filters',
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: const TabBar(
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle:
                    TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                unselectedLabelStyle:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: 'Winners List'),
                  Tab(text: 'User Summary'),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 8),
            _buildSummaryCards(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 3, color: AppColors.primary))
                  : TabBarView(
                      children: [
                        _groupedWinners.isEmpty
                            ? _buildEmptyState()
                            : _buildWinnersList(),
                        _userSummary.isEmpty
                            ? _buildEmptyState()
                            : _buildUserSummary(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final double netTotal = _totalAmount + _totalCommission;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
                'Total Prize',
                '₹${_totalAmount.toStringAsFixed(0)}',
                Icons.payments_rounded,
                Colors.green),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
                'Win Comm',
                '₹${_totalCommission.toStringAsFixed(0)}',
                Icons.account_balance_wallet_rounded,
                Colors.blue),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
                'Total Amount',
                '₹${netTotal.toStringAsFixed(0)}',
                Icons.summarize,
                Colors.purple),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32), topRight: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 12),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, color: AppColors.primary),
                    SizedBox(width: 12),
                    Text('FILTER REPORT',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                        child: _buildDatePicker('START DATE', _fromDate, (d) {
                      setState(() => _fromDate = d);
                      setSheetState(() {});
                    })),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildDatePicker('END DATE', _toDate, (d) {
                      setState(() => _toDate = d);
                      setSheetState(() {});
                    })),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDropdown<GameModel>(
                  'GAME',
                  _selectedGame,
                  [
                    const DropdownMenuItem(
                        value: null, child: Text('ALL GAMES')),
                    ..._games.map((g) => DropdownMenuItem(
                        value: g,
                        child: Text(g.name.toUpperCase(),
                            overflow: TextOverflow.ellipsis))),
                  ],
                  (val) {
                    setState(() => _selectedGame = val);
                    setSheetState(() {});
                  },
                  Icons.games_rounded,
                ),
                const SizedBox(height: 16),
                if (_userRole != 'SUB_DEALER')
                  _buildDropdown<UserModel>(
                    'AGENT',
                    _selectedAgent,
                    [
                      const DropdownMenuItem(
                          value: null, child: Text('ALL AGENTS')),
                      if (_currentUser != null)
                        DropdownMenuItem(
                            value: _currentUser, child: const Text('SELF')),
                      ..._agents.where((a) => a.id != _currentUser?.id).map(
                          (u) => DropdownMenuItem(
                              value: u,
                              child: Text(u.username.toUpperCase(),
                                  overflow: TextOverflow.ellipsis))),
                    ],
                    (val) {
                      setState(() => _selectedAgent = val);
                      setSheetState(() {});
                    },
                    Icons.person_pin_rounded,
                  ),
                const SizedBox(height: 16),
                if (_userRole != 'SUB_DEALER')
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.percent_rounded,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 12),
                            const Text(
                              'AGENT RATE',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey),
                            ),
                          ],
                        ),
                        Switch(
                          value: _agentRate,
                          onChanged: (val) {
                            setState(() => _agentRate = val);
                            setSheetState(() {});
                          },
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SEARCH NUMBER',
                        style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.black.withOpacity(0.05)),
                      ),
                      child: TextField(
                        controller: _numberController,
                        decoration: InputDecoration(
                          hintText: 'ENTER NUMBER...',
                          hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                          border: InputBorder.none,
                          icon: Icon(Icons.search_rounded,
                              color: Colors.grey[400], size: 20),
                        ),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6))
                      ]),
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            setSheetState(() {});
                            await _fetchReport();
                            if (mounted) Navigator.pop(context);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.analytics_rounded, size: 20),
                        SizedBox(width: 10),
                        Text('APPLY FILTERS',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return const SizedBox.shrink();
  }

  Widget _buildDatePicker(
      String label, DateTime date, Function(DateTime) onPicked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now());
            if (picked != null) onPicked(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(color: Colors.black.withOpacity(0.05)),
                borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 16, color: Colors.grey[400]),
                const SizedBox(width: 8),
                Text(DateFormat('dd/MM/yyyy').format(date),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>(String label, T? value,
      List<DropdownMenuItem<T>> items, Function(T?) onChanged,
      [IconData? icon]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(color: Colors.black.withOpacity(0.05)),
              borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: value,
                    isExpanded: true,
                    hint: Text('SELECT',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.bold)),
                    items: items,
                    onChanged: onChanged,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87),
                    icon: Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey[400]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWinnersList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _groupedWinners.length,
      itemBuilder: (context, index) {
        final group = _groupedWinners[index];
        final String prizeType =
            (group['winning_prize_type'] ?? 'WIN').toUpperCase();
        final double prizeAmount =
            (group['total_prize'] as num?)?.toDouble() ?? 0.0;
        final double commAmount =
            (group['total_comm'] as num?)?.toDouble() ?? 0.0;
        final double totalPay = prizeAmount + commAmount;
        final List users = group['users'] ?? [];

        return InkWell(
          onTap: () => _showUserWiseDetail(group),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  color: prizeType == 'BOX (1ST PRIZE) EXACT'
                      ? const Color(0xFF1D8740) // dark green — exact match
                      : prizeType == 'BOX2 (1ND PRIZE)'
                          ? const Color(0xFF2A9FF3) // blue — permutation match
                          : prizeType.contains('1ST')
                              ? const Color(0xFF1D8740)
                              : prizeType.contains('2ND')
                                  ? const Color(0xFF0E799F)
                                  : prizeType.contains('3RD')
                                      ? const Color(0xFFDE8D0C)
                                      : prizeType.contains('4TH')
                                          ? const Color(0xFF6E378E)
                                          : prizeType.contains('5TH')
                                              ? const Color(0xFF104282)
                                              : const Color(0xFFD1C4E9),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        prizeType,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 0.5,
                          color: (prizeType.contains('1ST') ||
                                  prizeType.contains('BOX') ||
                                  prizeType.contains('2ND') ||
                                  prizeType.contains('3RD') ||
                                  prizeType.contains('4TH') ||
                                  prizeType.contains('5TH'))
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'NUMBER:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: (prizeType.contains('1ST') ||
                                      prizeType.contains('BOX') ||
                                      prizeType.contains('2ND') ||
                                      prizeType.contains('3RD') ||
                                      prizeType.contains('4TH') ||
                                      prizeType.contains('5TH'))
                                  ? Colors.white70
                                  : Colors.black.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            group['number'] ?? '',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              color: (prizeType.contains('1ST') ||
                                      prizeType.contains('BOX') ||
                                      prizeType.contains('2ND') ||
                                      prizeType.contains('3RD') ||
                                      prizeType.contains('4TH') ||
                                      prizeType.contains('5TH'))
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Body
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left: Count
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Text(
                              'COUNT:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${group['total_count'] ?? 1}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right: Summary Table
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            _buildPriceRow(
                                'TOTAL:', prizeAmount.toStringAsFixed(0)),
                            const SizedBox(height: 6),
                            _buildPriceRow(
                                'COMM.:', commAmount.toStringAsFixed(0)),
                            const Padding(
                              padding: EdgeInsets.only(top: 4, bottom: 4),
                              child: Divider(height: 1, thickness: 1),
                            ),
                            _buildPriceRow(
                                'TOTAL:', totalPay.toStringAsFixed(0),
                                isBold: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Optional: User/Game Info (Small footer to keep track)
                // Footer: Aggregate Info
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  color: Colors.grey[50],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${users.length} USERS WON',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary.withOpacity(0.6)),
                      ),
                      Row(
                        children: [
                          Text(
                            (group['type'] ?? '').toUpperCase(),
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary.withOpacity(0.5)),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            (group['game_name'] ?? 'GAME').toUpperCase(),
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.grey[400]),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 10, color: Colors.grey[300]),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showUserWiseDetail(Map<String, dynamic> group) {
    final prizeType = (group['winning_prize_type'] ?? 'WIN').toUpperCase();
    final List users = group['users'] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: prizeType.contains('1ST')
                          ? const Color(0xFF1D8740).withOpacity(0.1)
                          : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.people_alt_rounded,
                      color: prizeType.contains('1ST')
                          ? const Color(0xFF1D8740)
                          : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('USER WISE DETAIL',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.grey[800])),
                        Text(
                          '$prizeType - NUMBER ${group['number']}',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: users.length,
                separatorBuilder: (c, i) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final win = users[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withOpacity(0.03)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (win['user_username'] ?? 'USER').toUpperCase(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    letterSpacing: 0.5),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'COUNT: ${win['count']}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[500]),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'RATE: ${((win['prize_rate'] ?? 0) as num).toStringAsFixed(0)} / ${((win['comm_rate'] ?? 0) as num).toStringAsFixed(0)}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary.withOpacity(0.7)),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'TYPE: ${win['type']}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            AppColors.primary.withOpacity(0.5)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${(win['winning_amount'] as num?)?.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15),
                            ),
                            Text(
                              'Comm: ₹${(win['winning_commission'] as num?)?.toStringAsFixed(2)}',
                              style: TextStyle(
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildPriceRow(String label, String value, {bool isBold = false}) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: isBold ? 18 : 14,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No winners found for these filters',
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildUserSummary() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: _userSummary.length,
            itemBuilder: (context, index) {
              final row = _userSummary[index];
              final String username =
                  row['user__username']?.toString().toUpperCase() ?? 'UNKNOWN';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 8))
                  ],
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.person_outline_rounded,
                          color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(username,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  letterSpacing: 0.5)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildBadge(
                                  row['user__role'] ?? '', Colors.blueGrey),
                              const SizedBox(width: 8),
                              Text('${row['win_count']} WINNERS',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.grey[400])),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                            '₹${(row['total_prize'] as num?)?.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w900,
                                fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(
                            'Comm: ₹${(row['total_comm'] as num?)?.toStringAsFixed(2)}',
                            style: TextStyle(
                                color: Colors.blue.withOpacity(0.7),
                                fontWeight: FontWeight.bold,
                                fontSize: 10)),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                              'Total: ₹${((row['total_prize'] as num? ?? 0) + (row['total_comm'] as num? ?? 0)).toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: Colors.purple,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Grand Total Section for User Summary
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2))
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL PAYABLE',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.8,
                      color: Colors.black54)),
              Text('₹${(_totalAmount + _totalCommission).toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppColors.primary)),
            ],
          ),
        ),
      ],
    );
  }
}
