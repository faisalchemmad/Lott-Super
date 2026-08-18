import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../utils/constants.dart';

class PurchaseReportDetailScreen extends StatelessWidget {
  final List<dynamic> reportData;
  final DateTime fromDate;
  final DateTime toDate;
  final String? gameName;
  final String? typeName;

  const PurchaseReportDetailScreen({
    super.key,
    required this.reportData,
    required this.fromDate,
    required this.toDate,
    this.gameName,
    this.typeName,
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
                    pw.Text('PURCHASE REPORT',
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
                  'Game: ${gameName ?? "All"}  |  Type: ${typeName ?? "All"}',
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
            headers: ['GAME', 'NUMBER', 'TYPE', 'QTY', 'PRICE'],
            data: reportData
                .map((item) => [
                      item['game__name'] ?? 'ALL',
                      item['number'].toString(),
                      item['type'].toString().toUpperCase(),
                      item['total_qty'].toString(),
                      (item['net_amount'] ?? item['total_price']).toString(),
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
        title: const Text('Purchase Report Results',
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
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
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
                            const SizedBox(height: 2),
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
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Qty: ${item['total_qty']}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87)),
                            Text('Rate: ₹${item['price_per_count'] ?? '-'}',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700])),
                            const SizedBox(height: 2),
                            Text('Net: ₹${item['net_amount'] ?? item['total_price']}',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.red[700])),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
                ),
                _buildTotalBar(),
              ],
            ),
    );
  }

  Widget _buildTotalBar() {
    double grandTotal = 0;
    int totalQty = 0;
    for (var item in reportData) {
      grandTotal += double.tryParse(item['net_amount']?.toString() ?? item['total_price']?.toString() ?? '0') ?? 0;
      totalQty += int.tryParse(item['total_qty']?.toString() ?? '0') ?? 0;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Total Quantity', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text('$totalQty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Total Net Amount', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text('₹${grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary)),
            ],
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
