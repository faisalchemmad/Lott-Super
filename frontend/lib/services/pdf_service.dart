import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> generateAndShareDailyReport({
    required String agentName,
    required DateTime fromDate,
    required DateTime toDate,
    required List<dynamic> reportData,
    required double totalSale,
    required double totalWinning,
    required double totalBalance,
  }) async {
    try {
      final pdf = pw.Document();
      final fmt = DateFormat('dd/MM/yyyy');

      // Use a consistent font that usually works
      final font = await PdfGoogleFonts.robotoRegular();
      final boldFont = await PdfGoogleFonts.robotoBold();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(
            base: font,
            bold: boldFont,
          ),
          build: (context) => [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('DAILY REPORT',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Lott Super',
                      style: pw.TextStyle(
                          fontSize: 14, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            // Info Row
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Agent: $agentName',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Period: ${fmt.format(fromDate)} - ${fmt.format(toDate)}'),
                  ],
                ),
                pw.Text('Generated: ${fmt.format(DateTime.now())}'),
              ],
            ),
            pw.SizedBox(height: 20),
            // Table
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF901C22)),
              rowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEEEEEE)),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 9),
              headers: ['DATE', 'USER', 'GAME', 'SALE', 'WINNING', 'BALANCE'],
              data: reportData.map((item) {
                return [
                  item['date'] ?? '-',
                  item['user'] ?? '-',
                  item['game'] ?? '-',
                  (item['sale'] ?? 0).toStringAsFixed(0),
                  (item['winning'] ?? 0).toStringAsFixed(0),
                  (item['balance'] ?? 0).toStringAsFixed(0),
                ];
              }).toList(),
              cellAlignments: {
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.centerRight,
              },
            ),
            pw.SizedBox(height: 20),
            // Summary
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Divider(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text('TOTAL SALE: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(width: 20),
                      pw.Text(totalSale.toStringAsFixed(0)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text('TOTAL WINNING: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(width: 20),
                      pw.Text(totalWinning.toStringAsFixed(0)),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text('NET BALANCE: ', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(width: 20),
                      pw.Text(totalBalance.toStringAsFixed(0), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      final pdfBytes = await pdf.save();

      if (kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        // For Desktop/Web, high-quality print preview is better
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: 'Daily_Report_${agentName}_${DateTime.now().millisecondsSinceEpoch}',
        );
      } else {
        // For Mobile, Share menu is standard
        final output = await getTemporaryDirectory();
        final file = File("${output.path}/daily_report_${DateTime.now().millisecondsSinceEpoch}.pdf");
        await file.writeAsBytes(pdfBytes);
        await Share.shareXFiles([XFile(file.path)], text: 'Daily Report - $agentName');
      }
    } catch (e) {
      debugPrint("PDF Generation Error: $e");
      rethrow;
    }
  }
}
