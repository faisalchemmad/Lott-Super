import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class ForwardPurchaseReportScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final DateTime fromDate;
  final DateTime toDate;
  final int? gameId;
  final int? adminId;
  final String? searchNumber;
  final String state;

  const ForwardPurchaseReportScreen({
    super.key,
    this.initialData,
    required this.fromDate,
    required this.toDate,
    this.gameId,
    this.adminId,
    this.searchNumber,
    this.state = 'ALL',
  });

  @override
  State<ForwardPurchaseReportScreen> createState() =>
      _ForwardPurchaseReportScreenState();
}

class _ForwardPurchaseReportScreenState
    extends State<ForwardPurchaseReportScreen> {
  bool _isLoading = false;
  List<dynamic> _invoices = [];
  double _totalSales = 0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _invoices = widget.initialData!['invoices'] ?? [];
      _totalSales = (widget.initialData!['sales'] ?? 0).toDouble();
      _totalCount = (widget.initialData!['count'] ?? 0).toInt();
    } else {
      _fetchReport();
    }
  }

  Future<void> _fetchReport() async {
    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final data = await apiService.getForwardPurchaseReport(
        fromDate: DateFormat('yyyy-MM-dd').format(widget.fromDate),
        toDate: DateFormat('yyyy-MM-dd').format(widget.toDate),
        gameId: widget.gameId,
        userId: widget.adminId,
        number: widget.searchNumber,
        state: widget.state,
      );

      setState(() {
        _invoices = data['invoices'] ?? [];
        _totalSales = (data['sales'] ?? 0).toDouble();
        _totalCount = (data['count'] ?? 0).toInt();
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

  Future<void> _deleteBet(int id) async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final success = await apiService.deleteForwardedBet(id);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Item deleted successfully'),
                backgroundColor: Colors.green),
          );
        }
        _fetchReport();
      } else {
        throw Exception('Delete failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error deleting: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmDelete(
      int id, String number, String type, int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text("Delete Forwarded Bet",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
              "Are you sure you want to delete Number: $number ($type) Qty: $count?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text("CANCEL"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(ctx).pop(true),
              child:
                  const Text("DELETE", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _deleteBet(id);
    }
  }

  Future<void> _generatePDF(List<Map<String, dynamic>> items) async {
    final pdf = pw.Document();
    final dateRange =
        "${DateFormat('dd/MM/yy').format(widget.fromDate)} - ${DateFormat('dd/MM/yy').format(widget.toDate)}";

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
                    pw.Text('FORWARD REPORT',
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
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Qty: $_totalCount',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.Text('Total Amount: Rs. ${_totalSales.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(
            headers: ['GAME', 'TYPE', 'NUM', 'QTY', 'AMOUNT'],
            data: items.map((item) {
              return [
                item['game'] ?? '',
                item['type'] ?? '',
                item['number'] ?? '',
                item['count']?.toString() ?? '0',
                "Rs. ${item['total'] ?? 0}",
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 10),
            headerDecoration:
                pw.BoxDecoration(color: PdfColor.fromHex('#901C22')),
            cellAlignment: pw.Alignment.center,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
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
          'Forward_Report_${DateFormat('ddMMyy').format(widget.fromDate)}.pdf',
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text('GAME', textAlign: TextAlign.left, style: headerStyle),
          ),
          Expanded(
            flex: 2,
            child:
                Text('TYPE', textAlign: TextAlign.center, style: headerStyle),
          ),
          Expanded(
            flex: 3,
            child: Text('NUM', textAlign: TextAlign.center, style: headerStyle),
          ),
          Expanded(
            flex: 2,
            child: Text('QTY', textAlign: TextAlign.right, style: headerStyle),
          ),
          Expanded(
            flex: 3,
            child:
                Text('AMOUNT', textAlign: TextAlign.right, style: headerStyle),
          ),
          SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> item, int index) {
    final bool isEven = index % 2 == 0;
    final gameName = (item['game'] ?? '').toString();
    final typeName = item['type'].toString().toUpperCase();
    final number = item['number'].toString();
    final qty = item['count'] ?? 0;
    final total = item['total'] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
              gameName,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
                color: AppColors.primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              typeName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                color: Color(0xFF374151),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: Colors.black,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$qty',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '₹$total',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13.5,
                color: Colors.green,
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon:
                  const Icon(Icons.delete_outline, color: Colors.red, size: 18),
              onPressed: () => _confirmDelete(
                item['id'],
                number,
                typeName,
                qty as int,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSameDay = widget.fromDate.year == widget.toDate.year &&
        widget.fromDate.month == widget.toDate.month &&
        widget.fromDate.day == widget.toDate.day;

    final dateRangeStr = isSameDay
        ? DateFormat('dd MMM yyyy').format(widget.fromDate)
        : '${DateFormat('dd MMM').format(widget.fromDate)} - ${DateFormat('dd MMM yyyy').format(widget.toDate)}';

    // Flatten all invoice items into flat list
    List<Map<String, dynamic>> flatItems = [];
    for (int i = 0; i < _invoices.length; i++) {
      var inv = _invoices[i];
      var items = inv['items'] as List<dynamic>? ?? [];
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
          'user': inv['user__username'],
        });
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Forward Report',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: () => _generatePDF(flatItems),
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
          // 1. Period & Summary Header Card
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            dateRangeStr,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.grey.shade800),
                          ),
                        ],
                      ),
                      if (widget.state != 'ALL')
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
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
                  const Divider(height: 14, thickness: 0.5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TOTAL COUNT',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600)),
                          const SizedBox(height: 2),
                          Text('$_totalCount',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('TOTAL AMOUNT',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600)),
                          const SizedBox(height: 2),
                          Text('₹${_totalSales.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.green)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 2. Table Column Header
          _buildTableHeader(),

          // 3. Table Rows
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : flatItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_rounded,
                                size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No forwarded bets found',
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
                          itemCount: flatItems.length,
                          itemBuilder: (context, index) {
                            return _buildTableRow(flatItems[index], index);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
