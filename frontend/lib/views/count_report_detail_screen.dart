import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CountReportDetailScreen extends StatelessWidget {
  final Map<String, dynamic> reportData;
  final bool agentRate;

  const CountReportDetailScreen({
    super.key,
    required this.reportData,
    this.agentRate = false,
  });

  @override
  Widget build(BuildContext context) {
    final List data = reportData['data'] ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Count Report',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTable(data),
            const SizedBox(height: 32),
            _buildTotalCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(List data) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: DataTable(
        columnSpacing: 16,
        horizontalMargin: 20,
        headingRowColor:
            MaterialStateProperty.all(AppColors.primary.withOpacity(0.05)),
        columns: [
          const DataColumn(
              label: Text('TYPE',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5))),
          const DataColumn(
              label: Text('COUNT',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5))),
          DataColumn(
              label: Text(agentRate ? 'RATE' : 'NET UNIT PRICE',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5))),
          const DataColumn(
              label: Text('CASH',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5))),
        ],
        rows: data.map((item) {
          return DataRow(cells: [
            DataCell(Text(item['type'].toString().toUpperCase(),
                style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 12))),
            DataCell(Text(item['total_count'].toString(),
                style: const TextStyle(color: Colors.black54, fontSize: 12))),
            DataCell(Text('₹${item['rate']}',
                style: const TextStyle(color: Colors.black54, fontSize: 12))),
            DataCell(Text('₹${item['total_cash']}',
                style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w900,
                    fontSize: 12))),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TOTAL COUNT',
                  style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8)),
              const SizedBox(height: 8),
              Text(reportData['total_count'].toString(),
                  style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 26,
                      fontWeight: FontWeight.w900)),
            ],
          ),
          Container(height: 40, width: 1, color: Colors.black12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('TOTAL CASH',
                  style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8)),
              const SizedBox(height: 8),
              Text('₹${reportData['total_cash']}',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 26,
                      fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }
}
