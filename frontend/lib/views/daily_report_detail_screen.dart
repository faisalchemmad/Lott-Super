import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/pdf_service.dart';
import '../utils/constants.dart';

class DailyReportDetailScreen extends StatefulWidget {
  final List<dynamic> initialReportData;
  final DateTime fromDate;
  final DateTime toDate;
  final int? agentId;
  final int? selectedGameId;
  final bool dayDetail;
  final bool gameDetail;
  final bool userWise;
  final bool agentRate;
  final String agentName;

  const DailyReportDetailScreen({
    super.key,
    required this.initialReportData,
    required this.fromDate,
    required this.toDate,
    this.agentId,
    this.selectedGameId,
    this.dayDetail = false,
    this.gameDetail = false,
    this.userWise = false,
    this.agentRate = false,
    required this.agentName,
  });

  @override
  State<DailyReportDetailScreen> createState() =>
      _DailyReportDetailScreenState();
}

class _DailyReportDetailScreenState extends State<DailyReportDetailScreen> {
  late List<dynamic> _reportData;
  late DateTime _currentFromDate;
  late DateTime _currentToDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _reportData = widget.initialReportData;
    _currentFromDate = widget.fromDate;
    _currentToDate = widget.toDate;
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final data = await apiService.getDailyReport(
        fromDate: DateFormat('yyyy-MM-dd').format(_currentFromDate),
        toDate: DateFormat('yyyy-MM-dd').format(_currentToDate),
        userId: widget.agentId,
        gameIds: widget.selectedGameId != null ? [widget.selectedGameId!] : null,
        dayDetail: widget.dayDetail,
        gameDetail: widget.gameDetail,
        userDetail: widget.userWise,
        agentRate: widget.agentRate,
      );

      setState(() {
        _reportData = data;
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

  Future<void> _selectDate(bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _currentFromDate : _currentToDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isFrom)
          _currentFromDate = picked;
        else
          _currentToDate = picked;
      });
      _refreshData();
    }
  }

  void _shareAsPdf(double totalSale, double totalWin, double totalBalance) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating PDF...'), duration: Duration(seconds: 1)),
    );
    try {
      await PdfService.generateAndShareDailyReport(
        agentName: widget.agentName,
        fromDate: _currentFromDate,
        toDate: _currentToDate,
        reportData: _reportData,
        totalSale: totalSale,
        totalWinning: totalWin,
        totalBalance: totalBalance,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always use gross sale for SALE column total
    double totalSale = _reportData.fold(0, (sum, item) => sum + ((item['sale'] ?? 0) as num));
    double totalCommission = _reportData.fold(0, (sum, item) => sum + ((item['commission'] ?? 0) as num));
    double totalWinning = _reportData.fold(0, (sum, item) => sum + ((item['winning'] ?? 0) as num));
    // Balance = net_sale (sale - commission) - winning
    double totalNetSale = totalSale - totalCommission;
    double totalBalance = totalNetSale - totalWinning;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Daily Report Results',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _shareAsPdf(totalSale, totalWinning, totalBalance),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildInfoBanner(),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildTable(),
                    ),
                  ),
                ),
                _buildSummaryFooter(totalSale, totalCommission, totalWinning, totalBalance),
              ],
            ),
    );
  }

  Widget _buildInfoBanner() {
    final fmt = DateFormat('dd MMM yyyy');
    // Banner color: orange-amber for Admin Rate (OFF), yellow for Agent Rate (ON)
    final bool isAdminRate = !widget.agentRate;
    final Color bannerColor = isAdminRate
        ? const Color(0xFFE8F4FD)  // light blue for Admin Rate
        : const Color(0xFFFFF3CD); // yellow for Agent Rate
    final Color textColor = isAdminRate
        ? const Color(0xFF0D6EFD)
        : const Color(0xFF856404);
    final IconData bannerIcon = isAdminRate
        ? Icons.admin_panel_settings_rounded
        : Icons.percent_rounded;
    final String bannerText = isAdminRate
        ? 'ADMIN RATE — Net sale after admin commission deduction'
        : 'AGENT RATE ON — Commission & winning by direct subordinate rates';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _selectDate(true),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              child: Row(
                children: [
                  Icon(Icons.date_range_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'PERIOD: ${fmt.format(_currentFromDate)} - ${fmt.format(_currentToDate)}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'CHANGE',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Always show rate mode indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
            color: bannerColor,
            child: Row(
              children: [
                Icon(bannerIcon, size: 12, color: textColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    bannerText,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    const headerStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );

    const cellStyle = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 11,
    );

    // Commission column label changes based on mode
    final String commLabel = widget.agentRate ? 'A.COMM' : 'COMM';

    return Table(
      columnWidths: const {
        0: FixedColumnWidth(52),  // DATE
        1: FixedColumnWidth(70),  // USER
        2: FixedColumnWidth(68),  // GAME
        3: FixedColumnWidth(62),  // SALE
        4: FixedColumnWidth(62),  // WINNING
        5: FixedColumnWidth(58),  // COMM
        6: FixedColumnWidth(62),  // BALANCE
      },
      children: [
        // Header Row
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFF901C22)),
          children: [
            _tableHeaderCell('DATE', headerStyle, leftPadding: 8),
            _tableHeaderCell('USER', headerStyle),
            _tableHeaderCell('GAME', headerStyle),
            _tableHeaderCell('SALE', headerStyle, alignRight: true, rightPadding: 8),
            _tableHeaderCell('WINNING', headerStyle, alignRight: true, rightPadding: 8),
            _tableHeaderCell(commLabel, headerStyle, alignRight: true, rightPadding: 6),
            _tableHeaderCell('BALANCE', headerStyle, alignRight: true, rightPadding: 8),
          ],
        ),
        // Data Rows
        ..._reportData.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final bool isEven = idx % 2 == 0;
          final double sale = (item['sale'] ?? 0).toDouble();
          final double commission = (item['commission'] ?? 0).toDouble();
          final double winning = (item['winning'] ?? 0).toDouble();
          final double balance = (item['balance'] ?? (sale - commission - winning)).toDouble();

          return TableRow(
            decoration: BoxDecoration(
              color: isEven ? const Color(0xFFD6D6D6) : const Color(0xFFE8E8E8),
            ),
            children: [
              _tableCell(item['date'] ?? '-', cellStyle, leftPadding: 8),
              _tableCell(item['user'] ?? '-', cellStyle),
              _tableCell(item['game'] ?? '-', cellStyle),
              _tableCell(sale.toStringAsFixed(0), cellStyle, alignRight: true, rightPadding: 8),
              _tableCell(winning.toStringAsFixed(0), cellStyle, alignRight: true, rightPadding: 8),
              _tableCell(
                commission.toStringAsFixed(0),
                const TextStyle(
                  color: Color(0xFF8B0000),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                alignRight: true,
                rightPadding: 6,
              ),
              _tableCell(
                balance.toStringAsFixed(0),
                TextStyle(
                  color: balance >= 0 ? Colors.black87 : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                alignRight: true,
                rightPadding: 8,
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _tableHeaderCell(String label, TextStyle style,
      {bool alignRight = false, double leftPadding = 4, double rightPadding = 4}) {
    return Padding(
      padding: EdgeInsets.only(top: 10, bottom: 10, left: leftPadding, right: rightPadding),
      child: Text(
        label,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: style,
      ),
    );
  }

  Widget _tableCell(String label, TextStyle style,
      {bool alignRight = false, double leftPadding = 2, double rightPadding = 2}) {
    return Padding(
      padding: EdgeInsets.only(top: 9, bottom: 9, left: leftPadding, right: rightPadding),
      child: Text(
        label,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildSummaryFooter(
      double sale, double commission, double winning, double balance) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _summaryColumn('SALE', sale),
          _summaryColumn(widget.agentRate ? 'A.COMM' : 'COMM', commission,
              valueColor: const Color(0xFF8B0000)),
          _summaryColumn('WINNING', winning),
          _summaryColumn('BALANCE', balance, isMain: true),
        ],
      ),
    );
  }

  Widget _summaryColumn(String label, double value,
      {bool isMain = false, Color? valueColor}) {
    final Color color = valueColor ??
        (isMain
            ? (value >= 0 ? Colors.green[700]! : Colors.red)
            : Colors.black87);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
        Text(
          value.toStringAsFixed(0),
          style: TextStyle(
            fontSize: isMain ? 16 : 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
