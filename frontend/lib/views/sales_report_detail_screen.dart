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
  final String state; // ADDED

  const SalesReportDetailScreen({
    super.key,
    required this.reportData,
    required this.fromDate,
    required this.toDate,
    this.fullView = false,
    required this.userRole,
    this.isAgentRate = true,
    this.searchNumber,
    this.state = 'ALL', // ADDED
  });

  @override
  State<SalesReportDetailScreen> createState() =>
      _SalesReportDetailScreenState();
}

class _SalesReportDetailScreenState extends State<SalesReportDetailScreen> {
  late Map<String, dynamic> _currentReportData;
  bool _showNetRate = true;

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
        gameId: _currentReportData[
            'game_id'], // Need to ensure this is available or pass original params
        userId: _currentReportData['user_id'],
        number: widget.searchNumber,
        fullView: widget.fullView,
        adminRate: widget.isAgentRate,
        state: widget.state, // ADDED
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
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('RECENT INVOICES',
                                style: TextStyle(
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                    fontSize: 14)),
                            Container(
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      if (!_showNetRate) {
                                        setState(() => _showNetRate = true);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: _showNetRate
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Net',
                                        style: TextStyle(
                                          color: _showNetRate
                                              ? Colors.white
                                              : Colors.grey[700],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      if (_showNetRate) {
                                        setState(() => _showNetRate = false);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: !_showNetRate
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Price',
                                        style: TextStyle(
                                          color: !_showNetRate
                                              ? Colors.white
                                              : Colors.grey[700],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: (widget.fullView ||
                                      (widget.searchNumber != null &&
                                          widget.searchNumber!.isNotEmpty))
                                  ? 0
                                  : 20),
                          child: widget.searchNumber != null &&
                                  widget.searchNumber!.isNotEmpty
                              ? _buildSearchNumberTable(invoices)
                              : _buildInvoiceList(invoices),
                        ),
                    ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Report Period Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_month_rounded,
                      color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('REPORT PERIOD',
                          style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text(
                        '${DateFormat('dd MMM').format(widget.fromDate)} - ${DateFormat('dd MMM yyyy').format(widget.toDate)}',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 2. Summary 4-Column Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildNewStatItem(Icons.people_alt_rounded,
                      'TotalCount', '${_currentReportData['count'] ?? 0}'),
                ),
                Container(width: 1, height: 60, color: Colors.grey.shade300),
                Expanded(
                  child: _buildNewStatItem(Icons.percent_rounded, commLabel,
                      '₹${_currentReportData['commission'] ?? 0}'),
                ),
                Container(width: 1, height: 60, color: Colors.grey.shade300),
                Expanded(
                  child: _buildNewStatItem(Icons.account_balance_wallet_rounded,
                      netLabel, '₹${_currentReportData['net'] ?? 0}'),
                ),
                Container(width: 1, height: 60, color: Colors.grey.shade300),
                Expanded(
                  child: _buildNewStatItem(Icons.bar_chart_rounded,
                      'Total Sales', '₹${_currentReportData['sales'] ?? 0}'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewStatItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissibleWrapper(dynamic inv, Widget child) {
    final invoiceId = inv['invoice_id'].toString();
    return Dismissible(
      key: Key(invoiceId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Invoice'),
            content:
                const Text('Are you sure you want to delete this invoice?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        try {
          final success = await Provider.of<ApiService>(context, listen: false)
              .deleteInvoice(invoiceId);
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invoice deleted successfully')),
            );
            setState(() {
              if (_currentReportData['invoices'] != null) {
                (_currentReportData['invoices'] as List).removeWhere(
                    (i) => i['invoice_id'].toString() == invoiceId);
              }
            });
            _reFetchData();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to delete invoice')),
            );
            _reFetchData();
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
          _reFetchData();
        }
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: child,
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

          return _buildDismissibleWrapper(
              inv,
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[200]!),
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    backgroundColor: Colors.transparent,
                    collapsedBackgroundColor: Colors.transparent,
                    iconColor: AppColors.primary,
                    collapsedIconColor: Colors.grey[600],
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.receipt_rounded,
                                    size: 16, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text('INV-${displayId}',
                                    style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900)),
                              ],
                            ),
                            Text('${dateStr}  ${timeStr}',
                                style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person_outline_rounded,
                                    size: 14, color: Colors.grey[400]),
                                const SizedBox(width: 4),
                                Text(inv['user__username'] ?? '',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                            Row(
                              children: [
                                Text('Qty: ${inv['count']}',
                                    style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (_showNetRate
                                            ? const Color(0xFF10B981)
                                            : Colors.blue)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                      '₹${_showNetRate ? (inv['net'] ?? inv['amount']) : (inv['amount'] ?? inv['net'])}',
                                      style: TextStyle(
                                          color: _showNetRate
                                              ? const Color(0xFF10B981)
                                              : Colors.blue.shade700,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    children: [
                      Container(
                          color: Colors.white,
                          child: Column(children: [
                            // Invoice Items Header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 12),
                              color: Colors.grey[100],
                              child: Row(
                                children: [
                                  const Expanded(
                                      flex: 3,
                                      child: Text('TYPE',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold))),
                                  const Expanded(
                                      flex: 2,
                                      child: Text('NUM',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold))),
                                  const Expanded(
                                      flex: 1,
                                      child: Text('QTY',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold))),
                                  Expanded(
                                      flex: 2,
                                      child: Text(
                                          _showNetRate ? 'NET TOTAL' : 'TOTAL',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: _showNetRate
                                                  ? const Color(0xFF10B981)
                                                  : Colors.black87))),
                                ],
                              ),
                            ),
                            // Invoice Items
                            ...items.map((item) {
                              final itemVal = _showNetRate
                                  ? (item['net'] ?? item['total'])
                                  : (item['total'] ?? item['net']);
                              return Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                      bottom:
                                          BorderSide(color: Colors.grey[200]!)),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 12),
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
                                      child: Text(item['number'].toString(),
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text('${item['count']}',
                                          style: const TextStyle(fontSize: 13)),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text('$itemVal',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: _showNetRate
                                                  ? const Color(0xFF10B981)
                                                  : Colors.black87)),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ]))
                    ],
                  ),
                ),
              ));
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

        return _buildDismissibleWrapper(
            inv,
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: InkWell(
                onTap: () async {
                  final result = await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      child: InvoiceDetailScreen(
                        invoiceId: invoiceId,
                        isAgentRate: widget.isAgentRate,
                      ),
                    ),
                  );
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
                                  fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Middle: Invoice Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'INV-$displayId',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      color: Colors.black87),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Qty: ${inv['count']}',
                                    style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.person_outline,
                                    size: 14, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    inv['user__username'] ?? '',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Trailing: Amount
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _showNetRate ? 'NET' : 'TOTAL',
                            style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${_showNetRate ? (inv['net'] ?? inv['amount']) : (inv['amount'] ?? inv['net'])}',
                            style: TextStyle(
                                color: _showNetRate
                                    ? const Color(0xFF10B981)
                                    : Colors.blue.shade700,
                                fontWeight: FontWeight.w900,
                                fontSize: 15),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ));
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
