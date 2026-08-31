import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class ForwardNetReportDetailScreen extends StatefulWidget {
  final List<dynamic> initialReportData;
  final DateTime fromDate;
  final DateTime toDate;
  final int? gameId;
  final int? adminId;
  final String state;

  const ForwardNetReportDetailScreen({
    super.key,
    required this.initialReportData,
    required this.fromDate,
    required this.toDate,
    this.gameId,
    this.adminId,
    this.state = 'ALL',
  });

  @override
  State<ForwardNetReportDetailScreen> createState() =>
      _ForwardNetReportDetailScreenState();
}

class _ForwardNetReportDetailScreenState
    extends State<ForwardNetReportDetailScreen> {
  late List<dynamic> _reportData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _reportData = widget.initialReportData;
  }

  Future<void> _fetchReport() async {
    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final data = await apiService.getForwardNetReport(
        fromDate: DateFormat('yyyy-MM-dd').format(widget.fromDate),
        toDate: DateFormat('yyyy-MM-dd').format(widget.toDate),
        gameId: widget.gameId,
        userId: widget.adminId,
        state: widget.state,
      );

      setState(() {
        _reportData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load report: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##,##0.00').format(amount);
  }

  Widget _buildSummaryHeader(
      double totalPurchase, double totalWinning, double totalBalance) {
    final isSameDay = widget.fromDate.year == widget.toDate.year &&
        widget.fromDate.month == widget.toDate.month &&
        widget.fromDate.day == widget.toDate.day;

    final dateRangeStr = isSameDay
        ? DateFormat('dd MMM yyyy').format(widget.fromDate)
        : '${DateFormat('dd MMM').format(widget.fromDate)} - ${DateFormat('dd MMM yyyy').format(widget.toDate)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      color: Colors.white,
      child: Column(
        children: [
          // 1. Report Period Card
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.calendar_month_rounded,
                          color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('REPORT PERIOD',
                            style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5)),
                        const SizedBox(height: 1),
                        Text(
                          dateRangeStr,
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ],
                ),
                if (widget.state != 'ALL')
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.state,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                  ),
              ],
            ),
          ),

          // 2. Summary 3-Column Card (Purchase, Winning, Balance)
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
                  child: _buildStatItem(Icons.bar_chart_rounded,
                      'Total Purchase', '₹${_formatAmount(totalPurchase)}'),
                ),
                Container(width: 1, height: 50, color: Colors.grey.shade200),
                Expanded(
                  child: _buildStatItem(Icons.emoji_events_rounded,
                      'Winning (Prz)', '₹${_formatAmount(totalWinning)}',
                      valueColor:
                          totalWinning > 0 ? const Color(0xFF10B981) : null),
                ),
                Container(width: 1, height: 50, color: Colors.grey.shade200),
                Expanded(
                  child: _buildStatItem(Icons.account_balance_wallet_rounded,
                      'Net Balance', '₹${_formatAmount(totalBalance)}',
                      valueColor: totalBalance >= 0
                          ? const Color(0xFF10B981)
                          : Colors.red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: valueColor ?? AppColors.primary),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600]),
              textAlign: TextAlign.center,
              maxLines: 1),
          const SizedBox(height: 1),
          Text(value,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: valueColor ?? const Color(0xFF1E293B)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    const headerStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
      color: Colors.white,
      letterSpacing: 0.5,
    );

    return Container(
      color: const Color(0xFF901C22),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text('DATE', textAlign: TextAlign.left, style: headerStyle),
          ),
          Expanded(
            flex: 3,
            child:
                Text('PURCHASE', textAlign: TextAlign.right, style: headerStyle),
          ),
          Expanded(
            flex: 3,
            child:
                Text('WINNING', textAlign: TextAlign.right, style: headerStyle),
          ),
          Expanded(
            flex: 3,
            child:
                Text('NET BAL', textAlign: TextAlign.right, style: headerStyle),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(dynamic item, int index) {
    final bool isEven = index % 2 == 0;
    final String dateStr = item['date'] ?? '';
    final double purchase = (item['purchase'] ?? 0).toDouble();
    final double winning = (item['fwd_winning_commi'] ?? 0).toDouble();
    final double balance = (item['balance'] ?? (purchase - winning)).toDouble();

    String formattedDate = dateStr;
    try {
      final parsed = DateTime.parse(dateStr);
      formattedDate = DateFormat('dd/MM/yyyy').format(parsed);
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isEven ? const Color(0xFFF9F9F9) : Colors.white,
        border:
            Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.8)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              formattedDate,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _formatAmount(purchase),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _formatAmount(winning),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: winning > 0 ? const Color(0xFF10B981) : Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _formatAmount(balance),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13.5,
                color: balance >= 0 ? const Color(0xFF10B981) : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
      double totalPurchase, double totalWinning, double totalBalance) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Expanded(
            flex: 3,
            child: Text(
              'TOTAL',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13.5,
                color: Color(0xFF901C22),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _formatAmount(totalPurchase),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13.5,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _formatAmount(totalWinning),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13.5,
                color:
                    totalWinning > 0 ? const Color(0xFF10B981) : Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _formatAmount(totalBalance),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: totalBalance >= 0 ? const Color(0xFF10B981) : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePDF() async {
    final pdf = pw.Document();
    final dateRange =
        "${DateFormat('dd/MM/yy').format(widget.fromDate)} - ${DateFormat('dd/MM/yy').format(widget.toDate)}";

    double totalPurchase = 0;
    double totalWinning = 0;
    for (var row in _reportData) {
      totalPurchase += (row['purchase'] ?? 0).toDouble();
      totalWinning += (row['fwd_winning_commi'] ?? 0).toDouble();
    }
    double totalBalance = totalPurchase - totalWinning;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('FORWARD NET REPORT',
                        style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#901C22'))),
                    pw.SizedBox(height: 4),
                    pw.Text('Date: $dateRange',
                        style: const pw.TextStyle(
                            fontSize: 11, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Lott Super',
                        style: pw.TextStyle(
                            fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 2),
                    pw.Text(
                        'Printed: ${DateFormat('dd/MM/yy HH:mm').format(DateTime.now())}',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Text('Purchase: Rs. ${_formatAmount(totalPurchase)}',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 11)),
                pw.Text('Winning: Rs. ${_formatAmount(totalWinning)}',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 11)),
                pw.Text('Net Bal: Rs. ${_formatAmount(totalBalance)}',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 11)),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(
            headers: ['DATE', 'PURCHASE', 'WINNING', 'NET BALANCE'],
            data: [
              ..._reportData.map((item) {
                final double p = (item['purchase'] ?? 0).toDouble();
                final double w = (item['fwd_winning_commi'] ?? 0).toDouble();
                final double b = (item['balance'] ?? (p - w)).toDouble();
                return [
                  item['date'] ?? '',
                  _formatAmount(p),
                  _formatAmount(w),
                  _formatAmount(b),
                ];
              }),
              [
                'TOTAL',
                _formatAmount(totalPurchase),
                _formatAmount(totalWinning),
                _formatAmount(totalBalance),
              ]
            ],
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 10),
            headerDecoration:
                pw.BoxDecoration(color: PdfColor.fromHex('#901C22')),
            cellAlignment: pw.Alignment.center,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
            cellStyle: const pw.TextStyle(fontSize: 9),
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name:
          'Forward_Net_Report_${DateFormat('ddMMyy').format(widget.fromDate)}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalPurchase = 0;
    double totalWinning = 0;
    for (var row in _reportData) {
      totalPurchase += (row['purchase'] ?? 0).toDouble();
      totalWinning += (row['fwd_winning_commi'] ?? 0).toDouble();
    }
    double totalBalance = totalPurchase - totalWinning;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Forward Net Report',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: _generatePDF,
            tooltip: "Share as PDF",
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchReport,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Summary Header
          _buildSummaryHeader(totalPurchase, totalWinning, totalBalance),

          // 2. Table Column Header
          _buildTableHeader(),

          // 3. Table Rows
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _reportData.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_rounded,
                                size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No forward net records found',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchReport,
                        child: ListView.builder(
                          itemCount: _reportData.length,
                          itemBuilder: (context, index) {
                            return _buildTableRow(_reportData[index], index);
                          },
                        ),
                      ),
          ),

          // 4. Bottom Total Bar
          if (_reportData.isNotEmpty)
            _buildTotalRow(totalPurchase, totalWinning, totalBalance),
        ],
      ),
    );
  }
}
