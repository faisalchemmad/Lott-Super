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
          pw.SizedBox(height: 10),
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
            headers: ['USER', 'GAME', 'NUMBER', 'TYPE', 'QTY'],
            data: reportData
                .map((item) => [
                      item['user__username'] ?? 'SYSTEM',
                      item['game__name'] ?? 'ALL',
                      item['number'].toString(),
                      item['type'].toString().toUpperCase(),
                      item['total_qty'].toString(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Number Report Results',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        centerTitle: true,
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
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reportData.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey[200]),
              itemBuilder: (context, index) {
                final item = reportData[index];
                return Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: Center(
                          child: Text(
                              item['type']
                                  .toString()
                                  .toUpperCase()
                                  .substring(0, 1),
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['type'].toString().toUpperCase(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(item['user__username'] ?? 'System Total',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 11)),
                            Text(item['game__name'] ?? '',
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(item['number'],
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                letterSpacing: 1)),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text('${item['total_qty']}',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary),
                            textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                );
              },
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
