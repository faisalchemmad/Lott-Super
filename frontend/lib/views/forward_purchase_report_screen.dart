import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class GameTypeOption {
  final String key;
  final String label;
  final String? state;
  final String? type;
  final bool isHeader;

  const GameTypeOption({
    required this.key,
    required this.label,
    this.state,
    this.type,
    this.isHeader = false,
  });
}

class ForwardPurchaseReportScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final DateTime fromDate;
  final DateTime toDate;
  final int? gameId;
  final int? adminId;
  final String? searchNumber;
  final String? selectedOptionKey;
  final String state;

  const ForwardPurchaseReportScreen({
    super.key,
    this.initialData,
    required this.fromDate,
    required this.toDate,
    this.gameId,
    this.adminId,
    this.searchNumber,
    this.selectedOptionKey,
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
  late String _selectedOptionKey;

  List<GameTypeOption> get _availableGameTypeOptions {
    if (widget.state == 'KL') {
      return const [
        GameTypeOption(key: 'KL:ALL', label: 'ALL KL TYPES', state: 'KL', type: null),
        GameTypeOption(key: 'KL:SUPER', label: 'SUPER', state: 'KL', type: 'SUPER'),
        GameTypeOption(key: 'KL:BOX', label: 'BOX', state: 'KL', type: 'BOX'),
        GameTypeOption(key: 'KL:A', label: 'A', state: 'KL', type: 'A'),
        GameTypeOption(key: 'KL:B', label: 'B', state: 'KL', type: 'B'),
        GameTypeOption(key: 'KL:C', label: 'C', state: 'KL', type: 'C'),
        GameTypeOption(key: 'KL:AB', label: 'AB', state: 'KL', type: 'AB'),
        GameTypeOption(key: 'KL:BC', label: 'BC', state: 'KL', type: 'BC'),
        GameTypeOption(key: 'KL:AC', label: 'AC', state: 'KL', type: 'AC'),
      ];
    } else if (widget.state == 'TN') {
      return const [
        GameTypeOption(key: 'TN:ALL', label: 'ALL TN TYPES', state: 'TN', type: null),
        GameTypeOption(key: 'TN:A', label: 'A', state: 'TN', type: 'A'),
        GameTypeOption(key: 'TN:B', label: 'B', state: 'TN', type: 'B'),
        GameTypeOption(key: 'TN:C', label: 'C', state: 'TN', type: 'C'),
        GameTypeOption(key: 'TN:AB', label: 'AB', state: 'TN', type: 'AB'),
        GameTypeOption(key: 'TN:BC', label: 'BC', state: 'TN', type: 'BC'),
        GameTypeOption(key: 'TN:AC', label: 'AC', state: 'TN', type: 'AC'),
        GameTypeOption(key: 'TN:3D-10', label: '3D-10', state: 'TN', type: '3D-10'),
        GameTypeOption(key: 'TN:3D-25', label: '3D-25', state: 'TN', type: '3D-25'),
        GameTypeOption(key: 'TN:3D-30', label: '3D-30', state: 'TN', type: '3D-30'),
        GameTypeOption(key: 'TN:3D-60', label: '3D-60', state: 'TN', type: '3D-60'),
        GameTypeOption(key: 'TN:4D-110', label: '4D-110', state: 'TN', type: '4D-110'),
        GameTypeOption(key: 'TN:4D-55', label: '4D-55', state: 'TN', type: '4D-55'),
        GameTypeOption(key: 'TN:4D-20', label: '4D-20', state: 'TN', type: '4D-20'),
      ];
    } else {
      return const [
        GameTypeOption(key: 'ALL', label: 'ALL TYPES', state: 'ALL', type: null),
        GameTypeOption(key: 'HEADER_KL', label: '─── KERALA (KL) ───', isHeader: true),
        GameTypeOption(key: 'KL:ALL', label: 'ALL KL', state: 'KL', type: null),
        GameTypeOption(key: 'KL:SUPER', label: 'SUPER', state: 'KL', type: 'SUPER'),
        GameTypeOption(key: 'KL:BOX', label: 'BOX', state: 'KL', type: 'BOX'),
        GameTypeOption(key: 'KL:A', label: 'A', state: 'KL', type: 'A'),
        GameTypeOption(key: 'KL:B', label: 'B', state: 'KL', type: 'B'),
        GameTypeOption(key: 'KL:C', label: 'C', state: 'KL', type: 'C'),
        GameTypeOption(key: 'KL:AB', label: 'AB', state: 'KL', type: 'AB'),
        GameTypeOption(key: 'KL:BC', label: 'BC', state: 'KL', type: 'BC'),
        GameTypeOption(key: 'KL:AC', label: 'AC', state: 'KL', type: 'AC'),
        GameTypeOption(key: 'HEADER_TN', label: '─── TAMIL NADU (TN) ───', isHeader: true),
        GameTypeOption(key: 'TN:ALL', label: 'ALL TN', state: 'TN', type: null),
        GameTypeOption(key: 'TN:A', label: 'A', state: 'TN', type: 'A'),
        GameTypeOption(key: 'TN:B', label: 'B', state: 'TN', type: 'B'),
        GameTypeOption(key: 'TN:C', label: 'C', state: 'TN', type: 'C'),
        GameTypeOption(key: 'TN:AB', label: 'AB', state: 'TN', type: 'AB'),
        GameTypeOption(key: 'TN:BC', label: 'BC', state: 'TN', type: 'BC'),
        GameTypeOption(key: 'TN:AC', label: 'AC', state: 'TN', type: 'AC'),
        GameTypeOption(key: 'TN:3D-10', label: '3D-10', state: 'TN', type: '3D-10'),
        GameTypeOption(key: 'TN:3D-25', label: '3D-25', state: 'TN', type: '3D-25'),
        GameTypeOption(key: 'TN:3D-30', label: '3D-30', state: 'TN', type: '3D-30'),
        GameTypeOption(key: 'TN:3D-60', label: '3D-60', state: 'TN', type: '3D-60'),
        GameTypeOption(key: 'TN:4D-110', label: '4D-110', state: 'TN', type: '4D-110'),
        GameTypeOption(key: 'TN:4D-55', label: '4D-55', state: 'TN', type: '4D-55'),
        GameTypeOption(key: 'TN:4D-20', label: '4D-20', state: 'TN', type: '4D-20'),
      ];
    }
  }

  @override
  void initState() {
    super.initState();
    String initialKey = widget.selectedOptionKey ?? 'ALL';
    if (widget.state == 'KL' && initialKey == 'ALL') {
      initialKey = 'KL:ALL';
    } else if (widget.state == 'TN' && initialKey == 'ALL') {
      initialKey = 'TN:ALL';
    }
    _selectedOptionKey = initialKey;

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

    String reqState = widget.state;
    String? reqType;

    if (_selectedOptionKey.contains(':')) {
      final parts = _selectedOptionKey.split(':');
      reqState = parts[0];
      reqType = parts[1] == 'ALL' ? null : parts[1];
    } else if (_selectedOptionKey != 'ALL') {
      reqType = _selectedOptionKey;
    }

    try {
      final data = await apiService.getForwardPurchaseReport(
        fromDate: DateFormat('yyyy-MM-dd').format(widget.fromDate),
        toDate: DateFormat('yyyy-MM-dd').format(widget.toDate),
        gameId: widget.gameId,
        userId: widget.adminId,
        number: widget.searchNumber,
        betType: reqType,
        state: reqState,
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
                    pw.Text('Date: $dateRange | Option: $_selectedOptionKey',
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
              final num rate = item['amount'] ?? 0;
              final rateStr =
                  (rate % 1 == 0) ? rate.toInt().toString() : rate.toString();
              return [
                item['game'] ?? '',
                item['type'] ?? '',
                item['number'] ?? '',
                "${item['count'] ?? 0} × $rateStr",
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
            flex: 2,
            child: Text('NUM', textAlign: TextAlign.center, style: headerStyle),
          ),
          Expanded(
            flex: 3,
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

    final num rate = item['amount'] ?? 0;
    final rateStr = (rate % 1 == 0) ? rate.toInt().toString() : rate.toString();

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
            flex: 2,
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
            flex: 3,
            child: RichText(
              textAlign: TextAlign.right,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$qty',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14.5,
                      color: AppColors.primary,
                    ),
                  ),
                  TextSpan(
                    text: ' × $rateStr',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '₹${(item['total'] ?? 0).toStringAsFixed(2)}',
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

    final validKeys = _availableGameTypeOptions
        .where((opt) => !opt.isHeader)
        .map((opt) => opt.key)
        .toSet();

    String? currentDropdownValue;
    if (validKeys.contains(_selectedOptionKey)) {
      currentDropdownValue = _selectedOptionKey;
    } else if (validKeys.isNotEmpty) {
      currentDropdownValue = validKeys.first;
    }

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
          // 1. Period & Summary Header Card with Game Type Selector
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
                      // Sectioned KL / TN Game Type Dropdown
                      if (currentDropdownValue != null)
                        Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: currentDropdownValue,
                              isDense: true,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                              items: _availableGameTypeOptions.map((opt) {
                                if (opt.isHeader) {
                                  return DropdownMenuItem<String>(
                                    value: opt.key,
                                    enabled: false,
                                    child: Text(
                                      opt.label,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: AppColors.primary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  );
                                }
                                return DropdownMenuItem<String>(
                                  value: opt.key,
                                  child: Text(
                                    opt.label,
                                    style: TextStyle(
                                      fontWeight: opt.key == 'ALL' || opt.key.endsWith(':ALL')
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null &&
                                    !val.startsWith('HEADER_') &&
                                    val != _selectedOptionKey) {
                                  setState(() {
                                    _selectedOptionKey = val;
                                  });
                                  _fetchReport();
                                }
                              },
                            ),
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
