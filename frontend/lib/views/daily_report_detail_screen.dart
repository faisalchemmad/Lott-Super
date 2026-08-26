import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
        gameIds:
            widget.selectedGameId != null ? [widget.selectedGameId!] : null,
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
        if (isFrom) {
          _currentFromDate = picked;
        } else {
          _currentToDate = picked;
        }
      });
      _refreshData();
    }
  }

  void _shareAsPdf(
      double totalSale, double totalWin, double totalBalance) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Generating PDF...'), duration: Duration(seconds: 1)),
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
          SnackBar(
              content: Text('Failed to generate PDF: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;

    // Always use gross sale for SALE column total
    double totalSale =
        _reportData.fold(0, (sum, item) => sum + ((item['sale'] ?? 0) as num));
    double totalCommission = _reportData.fold(
        0, (sum, item) => sum + ((item['commission'] ?? 0) as num));
    double totalWinning = _reportData.fold(
        0, (sum, item) => sum + ((item['winning'] ?? 0) as num));
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
                _buildSummaryHeader(
                    totalSale, totalCommission, totalWinning, totalBalance),
                _buildTableHeader(isDesktop),
                Expanded(
                  child: _reportData.isEmpty
                      ? const Center(
                          child: Text(
                            'No data found for selected period',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _reportData.length,
                          separatorBuilder: (c, i) => const Divider(
                              height: 1, color: Color(0xFFEEEEEE)),
                          itemBuilder: (context, index) => _buildReportRow(
                              _reportData[index], index, isDesktop),
                        ),
                ),
                _buildSummaryFooter(totalSale, totalCommission, totalWinning,
                    totalBalance, isDesktop),
              ],
            ),
    );
  }

  Widget _buildSummaryHeader(double totalSale, double totalCommission,
      double totalWinning, double totalBalance) {
    final fmt = DateFormat('dd MMM');
    final fmtYear = DateFormat('dd MMM yyyy');
    final bool isAdminRate = !widget.agentRate;
    final Color bannerColor =
        isAdminRate ? const Color(0xFFE8F4FD) : const Color(0xFFFFF3CD);
    final Color textColor =
        isAdminRate ? const Color(0xFF0D6EFD) : const Color(0xFF856404);
    final IconData bannerIcon = isAdminRate
        ? Icons.admin_panel_settings_rounded
        : Icons.percent_rounded;
    final String bannerText = isAdminRate
        ? 'ADMIN RATE — Net sale after admin commission deduction'
        : 'AGENT RATE ON — Commission & winning by direct subordinate rates';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Report Period Card
          InkWell(
            onTap: () => _selectDate(true),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.calendar_month_rounded,
                        color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REPORT PERIOD',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${fmt.format(_currentFromDate)} - ${fmtYear.format(_currentToDate)}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'CHANGE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 2. Summary 4-Stat Card (like Sales Report)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildNewStatItem(Icons.bar_chart_rounded,
                      'Total Sales', '₹${totalSale.toStringAsFixed(0)}'),
                ),
                Container(width: 1, height: 50, color: Colors.grey.shade200),
                Expanded(
                  child: _buildNewStatItem(Icons.emoji_events_rounded,
                      'Winning (Prz)', '₹${totalWinning.toStringAsFixed(0)}',
                      valueColor:
                          totalWinning > 0 ? Colors.red.shade700 : null),
                ),
                Container(width: 1, height: 50, color: Colors.grey.shade200),
                Expanded(
                  child: _buildNewStatItem(
                      Icons.percent_rounded,
                      widget.agentRate ? 'Agent Comm' : 'Discount (Dc)',
                      '₹${totalCommission.toStringAsFixed(0)}',
                      valueColor: const Color(0xFF8B0000)),
                ),
                Container(width: 1, height: 50, color: Colors.grey.shade200),
                Expanded(
                  child: _buildNewStatItem(Icons.account_balance_wallet_rounded,
                      'Net Total', '₹${totalBalance.toStringAsFixed(0)}',
                      valueColor: totalBalance >= 0
                          ? const Color(0xFF10B981)
                          : Colors.red),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Rate mode note
          Container(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
            decoration: BoxDecoration(
              color: bannerColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(bannerIcon, size: 11, color: textColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    bannerText,
                    style: TextStyle(
                      fontSize: 8.5,
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

  Widget _buildNewStatItem(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: AppColors.primary, size: 16),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: Colors.grey[600],
                fontSize: 9,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                  color: valueColor ?? AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(bool isDesktop) {
    const headerStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 11,
      letterSpacing: 0.5,
    );

    return Container(
      color: const Color(0xFF901C22),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: const Row(
        children: [
          Expanded(
            flex: 32,
            child: Text('USER', style: headerStyle),
          ),
          Expanded(
            flex: 22,
            child:
                Text('SALES', textAlign: TextAlign.right, style: headerStyle),
          ),
          Expanded(
            flex: 24,
            child:
                Text('PRZ/DC', textAlign: TextAlign.right, style: headerStyle),
          ),
          Expanded(
            flex: 22,
            child:
                Text('TOTAL', textAlign: TextAlign.right, style: headerStyle),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(dynamic item, int index, bool isDesktop) {
    final bool isEven = index % 2 == 0;
    final double sale = (item['sale'] ?? 0).toDouble();
    final double commission = (item['commission'] ?? 0).toDouble();
    final double winning = (item['winning'] ?? 0).toDouble();
    final double balance =
        (item['balance'] ?? (sale - commission - winning)).toDouble();

    String title = item['user'] ?? '-';
    if (title == '-' || title == 'ALL') {
      if (item['game'] != null &&
          item['game'] != '-' &&
          item['game'] != 'ALL') {
        title = item['game'];
      } else if (item['date'] != null && item['date'] != '-') {
        title = item['date'];
      }
    }

    List<String> subItems = [];
    if (item['game'] != null &&
        item['game'] != '-' &&
        item['game'] != 'ALL' &&
        item['game'] != title) {
      subItems.add(item['game']);
    }
    if (item['date'] != null && item['date'] != '-' && item['date'] != title) {
      subItems.add(item['date']);
    }
    String subTitle = subItems.join(' • ');

    return Container(
      color: isEven ? const Color(0xFFF9F9F9) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // USER column
          Expanded(
            flex: 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subTitle.isNotEmpty)
                  Text(
                    subTitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // SALES column
          Expanded(
            flex: 22,
            child: Text(
              sale.toStringAsFixed(0),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
          // PRZ/DC column
          Expanded(
            flex: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  winning.toStringAsFixed(0),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: winning > 0 ? Colors.red.shade700 : Colors.black87,
                  ),
                ),
                if (commission > 0)
                  Text(
                    'Dc: ${commission.toStringAsFixed(0)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B0000),
                    ),
                  ),
              ],
            ),
          ),
          // TOTAL column
          Expanded(
            flex: 22,
            child: Text(
              balance.toStringAsFixed(0),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: balance >= 0 ? const Color(0xFF10B981) : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryFooter(double sale, double commission, double winning,
      double balance, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _summaryColumn('SALES', sale, Colors.black87),
          _summaryColumn('PRZ / DC', winning, Colors.red.shade700,
              subValue: commission),
          _summaryColumn('TOTAL', balance,
              balance >= 0 ? const Color(0xFF10B981) : Colors.red,
              isMain: true),
        ],
      ),
    );
  }

  Widget _summaryColumn(String label, double value, Color valueColor,
      {double? subValue, bool isMain = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          isMain ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600])),
        Text(
          value.toStringAsFixed(0),
          style: TextStyle(
            fontSize: isMain ? 15 : 13,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        if (subValue != null && subValue > 0)
          Text(
            'Dc: ${subValue.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B0000),
            ),
          ),
      ],
    );
  }
}
