import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../utils/constants.dart';

class NumberReportDetailScreen extends StatelessWidget {
  final List<dynamic> reportData;
  final DateTime fromDate;
  final DateTime toDate;
  final String? gameName;
  final String? typeName;
  final String? agentName;

  const NumberReportDetailScreen({
    super.key,
    required this.reportData,
    required this.fromDate,
    required this.toDate,
    this.gameName,
    this.typeName,
    this.agentName,
  });

  Future<void> _generatePDF() async {
    final pdf = pw.Document();
    final dateRange =
        "${DateFormat('dd/MM/yy').format(fromDate)} - ${DateFormat('dd/MM/yy').format(toDate)}";

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('NUMBER REPORT',
                        style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey800)),
                    pw.Text('Date: $dateRange',
                        style: const pw.TextStyle(
                            fontSize: 12, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Lott Super',
                        style: pw.TextStyle(
                            fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                        'Printed: ${DateFormat('dd/MM/yy HH:mm').format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          const pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Text(
                  'Game: ${gameName ?? "All"}  |  Type: ${typeName ?? "All"}  |  Agent: ${agentName ?? "All"}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.blueGrey700),
            cellAlignment: pw.Alignment.centerLeft,
            headers: ['USER', 'TYPE', 'NUM', 'QTY', 'FWD'],
            data: reportData
                .map((item) => [
                      (item['user__username'] ?? 'SYSTEM')
                          .toString()
                          .toUpperCase(),
                      item['type'].toString().toUpperCase(),
                      item['number'].toString(),
                      item['total_qty'].toString(),
                      (item['forwarded_qty'] ?? 0).toString(),
                    ])
                .toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name:
            'Number_Report_${DateFormat('ddMMyy').format(DateTime.now())}.pdf');
  }

  Widget _buildTableHeader() {
    const headerStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 12,
      letterSpacing: 0.5,
    );

    return Container(
      color: const Color(0xFF901C22),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text('USER', textAlign: TextAlign.left, style: headerStyle),
          ),
          Expanded(
            flex: 3,
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
        ],
      ),
    );
  }

  Widget _buildTableRow(dynamic item, int index) {
    final bool isEven = index % 2 == 0;
    final userName =
        (item['user__username'] ?? 'SYSTEM').toString().toUpperCase();
    final typeName = item['type'].toString().toUpperCase();
    final number = item['number'].toString();
    final qty = item['total_qty'] ?? 0;
    final fwdQty = item['forwarded_qty'] ?? 0;

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
              userName,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
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
                fontSize: 14,
                color: Colors.black,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$qty',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
                if (fwdQty > 0)
                  Text(
                    'Fwd: $fwdQty',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
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
    final isSameDay = fromDate.year == toDate.year &&
        fromDate.month == toDate.month &&
        fromDate.day == toDate.day;

    final dateRangeStr = isSameDay
        ? DateFormat('dd MMM yyyy').format(fromDate)
        : '${DateFormat('dd MMM').format(fromDate)} - ${DateFormat('dd MMM yyyy').format(toDate)}';

    final totalQty = reportData.fold<int>(0,
        (sum, item) => sum + (int.tryParse(item['total_qty'].toString()) ?? 0));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Number Report',
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
        ],
      ),
      body: reportData.isEmpty
          ? _buildNoData()
          : Column(
              children: [
                // 1. Report Period Header Card
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                        Expanded(
                          child: Column(
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
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Total Qty: $totalQty',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 2. Table Header
                _buildTableHeader(),
                // 3. Table Rows
                Expanded(
                  child: ListView.builder(
                    itemCount: reportData.length,
                    itemBuilder: (context, index) =>
                        _buildTableRow(reportData[index], index),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNoData() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No results found',
              style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        ],
      ),
    );
  }
}
