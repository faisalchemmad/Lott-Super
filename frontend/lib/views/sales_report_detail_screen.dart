import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'invoice_detail_screen.dart';

class SalesReportDetailScreen extends StatefulWidget {
  final Map<String, dynamic> reportData;
  final DateTime fromDate;
  final DateTime toDate;
  final bool fullView;
  final String userRole;
  final bool isAgentRate;
  final String? searchNumber;

  const SalesReportDetailScreen({
    super.key,
    required this.reportData,
    required this.fromDate,
    required this.toDate,
    this.fullView = false,
    required this.userRole,
    this.isAgentRate = true,
    this.searchNumber,
  });

  @override
  State<SalesReportDetailScreen> createState() =>
      _SalesReportDetailScreenState();
}

class _SalesReportDetailScreenState extends State<SalesReportDetailScreen> {
  late Map<String, dynamic> _currentReportData;

  @override
  void initState() {
    super.initState();
    _currentReportData = widget.reportData;
  }

  Future<void> _reFetchData() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final data = await apiService.getSalesReport(
        fromDate: DateFormat('yyyy-MM-dd').format(widget.fromDate),
        toDate: DateFormat('yyyy-MM-dd').format(widget.toDate),
        gameId: _currentReportData['game_id'], // Need to ensure this is available or pass original params
        userId: _currentReportData['user_id'],
        number: widget.searchNumber,
        fullView: widget.fullView,
        adminRate: widget.isAgentRate,
      );
      setState(() {
        _currentReportData = data;
      });
    } catch (e) {
      print('Error re-fetching sales report: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    List invoices = _currentReportData['invoices'] ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
            widget.searchNumber != null && widget.searchNumber!.isNotEmpty
                ? 'Search Result'
                : (widget.fullView ? 'Full Sales Report' : 'Detailed Report'),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildSummaryHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text('RECENT INVOICES',
                              style: TextStyle(
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  fontSize: 14)),
                        ),
                        const SizedBox(height: 16),
                        if (invoices.isEmpty)
                          Center(
                              child: Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long_rounded,
                                    size: 60, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text('No invoices found',
                                    style: TextStyle(color: Colors.grey[400])),
                              ],
                            ),
                          ))
                        else
                          widget.searchNumber != null &&
                                  widget.searchNumber!.isNotEmpty
                              ? _buildSearchNumberTable(invoices)
                              : _buildInvoiceList(invoices),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.calendar_today_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('REPORT PERIOD',
                  style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(
                '${DateFormat('dd MMM').format(widget.fromDate)} - ${DateFormat('dd MMM yyyy').format(widget.toDate)}',
                style: const TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    bool isAdminView = widget.userRole == 'SUPER_ADMIN' ||
        widget.userRole == 'ADMIN' ||
        widget.userRole == 'AGENT' ||
        widget.userRole == 'DEALER';

    String commLabel = isAdminView
        ? (widget.isAgentRate
            ? (widget.userRole == 'AGENT'
                ? 'Agent Comm'
                : (widget.userRole == 'DEALER'
                    ? 'Dealer Comm'
                    : (widget.userRole == 'SUPER_ADMIN'
                        ? 'User Comm'
                        : 'Admin Comm')))
            : 'Self Comm')
        : 'Total Commission';

    String netLabel = isAdminView
        ? (widget.isAgentRate
            ? (widget.userRole == 'AGENT'
                ? 'Agent Net'
                : (widget.userRole == 'DEALER'
                    ? 'Dealer Net'
                    : (widget.userRole == 'SUPER_ADMIN'
                        ? 'User Net'
                        : 'Admin Net')))
            : 'Self Net')
        : 'Net Amount';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF4F4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('REPORT PERIOD',
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  Text(
                    '${DateFormat('dd MMM').format(widget.fromDate)} - ${DateFormat('dd MMM yyyy').format(widget.toDate)}',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildRedStatItem(
                    'TotalCount:', '${_currentReportData['count'] ?? 0}'),
              ),
              Expanded(
                child: _buildRedStatItem(
                    commLabel, '₹${_currentReportData['commission'] ?? 0}'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildRedStatItem(
                    netLabel, '₹${_currentReportData['net'] ?? 0}'),
              ),
              Expanded(
                child: _buildRedStatItem(
                    'Total Sales', '₹${_currentReportData['sales'] ?? 0}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRedStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              color: Colors.grey[800],
              fontSize: 13,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
              color: AppColors.primary,
              fontSize: 15,
              fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildInvoiceList(List invoices) {
    if (widget.fullView) {
      return Column(
        children: invoices.map((inv) {
          final items = inv['items'] ?? [];
          final createdAt = DateTime.parse(inv['created_at']);
          final dateStr = DateFormat('yyyy-MM-dd').format(createdAt);
          final timeStr = DateFormat('HH:mm:ss').format(createdAt);
          final displayId = inv['invoice_id'].toString();

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                // Invoice Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  color: const Color(0xFF1A233E), // Dark Navy Blue
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dateStr,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                            Text(timeStr,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(displayId,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontStyle: FontStyle.italic)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(inv['user__username'] ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text('${inv['count']}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                            '${(widget.userRole == 'SUPER_ADMIN' || widget.userRole == 'ADMIN' || widget.userRole == 'AGENT' || widget.userRole == 'DEALER') ? inv['net'] : inv['amount']}',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                color: (widget.userRole == 'SUPER_ADMIN' ||
                                        widget.userRole == 'ADMIN' ||
                                        widget.userRole == 'AGENT' ||
                                        widget.userRole == 'DEALER')
                                    ? const Color(0xFF10B981)
                                    : Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ),
                // Invoice Items Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  color: Colors.grey[100],
                  child: Row(
                    children: [
                      const Expanded(
                          flex: 3,
                          child: Text('TYPE',
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold))),
                      const Expanded(
                          flex: 2,
                          child: Text('NUM',
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold))),
                      const Expanded(
                          flex: 1,
                          child: Text('QTY',
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold))),
                      if (widget.userRole == 'SUPER_ADMIN' ||
                          widget.userRole == 'ADMIN' ||
                          widget.userRole == 'AGENT' ||
                          widget.userRole == 'DEALER') ...[
                        const Expanded(
                            flex: 2,
                            child: Text('NET',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold))),
                        const Expanded(
                            flex: 2,
                            child: Text('TOT',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981)))),
                      ] else
                        const Expanded(
                            flex: 2,
                            child: Text('TOTAL',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                // Invoice Items
                ...items.map((item) {
                  return Container(
                    decoration: BoxDecoration(
                      border:
                          Border(bottom: BorderSide(color: Colors.grey[200]!)),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                              '${inv['game__name']}-${item['type']}'
                                  .toUpperCase(),
                              style: const TextStyle(fontSize: 12)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(item['number'],
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text('${item['count']}',
                              style: const TextStyle(fontSize: 13)),
                        ),
                        if (widget.userRole == 'SUPER_ADMIN' ||
                            widget.userRole == 'ADMIN' ||
                            widget.userRole == 'AGENT' ||
                            widget.userRole == 'DEALER') ...[
                          Expanded(
                            flex: 2,
                            child: Text(
                                (item['net'] / item['count'])
                                    .toStringAsFixed(2),
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 12)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('${item['net']}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981))),
                          ),
                        ] else
                          Expanded(
                            flex: 2,
                            child: Text('${item['total']}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 13)),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }).toList(),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        final inv = invoices[index];
        final invoiceId = inv['invoice_id'];
        final displayId = invoiceId.toString().split('-').last.toUpperCase();

        final createdAtLocal =
            DateTime.parse(inv['created_at'].toString()).toLocal();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: InkWell(
            onTap: () async {
              final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => InvoiceDetailScreen(
                          invoiceId: invoiceId,
                          isAgentRate: widget.isAgentRate)));
              if (result == true) {
                _reFetchData();
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Leading: Date/Time Vertical Column
                  Container(
                    width: 50,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('dd').format(createdAtLocal),
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              height: 1.1),
                        ),
                        Text(
                          DateFormat('MMM')
                              .format(createdAtLocal)
                              .toUpperCase(),
                          style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w900,
                              fontSize: 9,
                              height: 1.1),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('HH:mm').format(createdAtLocal),
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: -0.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Info Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('INV-$displayId',
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                fontSize: 15)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded,
                                size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(inv['user__username'] ?? 'User',
                                style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            const Icon(Icons.videogame_asset_outlined,
                                size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(inv['game__name'] ?? 'Game',
                                style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Financial Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('₹${inv['net']}',
                            style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.w900,
                                fontSize: 16)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Qty: ${inv['count']}${(widget.userRole == 'SUPER_ADMIN' || widget.userRole == 'ADMIN' || widget.userRole == 'AGENT' || widget.userRole == 'DEALER') ? ' | Rate: ₹${(inv['net'] / inv['count']).toStringAsFixed(2)}' : ''}',
                        style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 10,
                            fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded,
                      color: Colors.grey[300], size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchNumberTable(List invoices) {
    // Collect all matching bets into a flat list
    List<Map<String, dynamic>> flatBets = [];
    for (var inv in invoices) {
      final items = inv['items'] ?? [];
      for (var item in items) {
        flatBets.add({
          'inv': inv['invoice_id'].toString(),
          'num': item['number'],
          'qty': item['count'],
          'game': inv['game__name'],
          'type': item['type'],
        });
      }
    }

    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFFAF4F4),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 4,
                child: Text('INV',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 13)),
              ),
              Expanded(
                flex: 2,
                child: Text('NUM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 13)),
              ),
              Expanded(
                flex: 2,
                child: Text('QTY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 13)),
              ),
              Expanded(
                flex: 2,
                child: Text('GAME',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 13)),
              ),
              Expanded(
                flex: 3,
                child: Text('TYPE',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 13)),
              ),
            ],
          ),
        ),
        // Data Rows
        ...flatBets.map((bet) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200], // Grey background as per image
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text('INV-${bet['inv']}',
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('${bet['num']}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('${bet['qty']}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('${bet['game']}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('${bet['type']}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
