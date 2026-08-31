import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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
          SnackBar(content: Text('Failed to load report: $e'), backgroundColor: Colors.red),
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
                content: Text('Forwarded item deleted successfully'),
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
          SnackBar(content: Text('Error deleting: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmDelete(int id, String number, String type, int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text("Delete Forwarded Bet", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text("Are you sure you want to delete Number: $number ($type) Qty: $count?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text("CANCEL"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text("DELETE", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _deleteBet(id);
    }
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

          // 2. Main List
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
                          padding: const EdgeInsets.all(12),
                          itemCount: flatItems.length,
                          itemBuilder: (context, index) {
                            final item = flatItems[index];
                            final dateStr = item['date'] != null
                                ? DateFormat('dd MMM, hh:mm a')
                                    .format(DateTime.parse(item['date']).toLocal())
                                : '';

                            return Dismissible(
                              key: Key('fwd_${item['id']}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade600,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text('DELETE',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(width: 8),
                                    Icon(Icons.delete_forever, color: Colors.white),
                                  ],
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Forwarded Bet'),
                                    content: Text(
                                        'Delete Number ${item['number']} (${item['type']})?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('CANCEL'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('DELETE',
                                            style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                                return confirmed == true;
                              },
                              onDismissed: (direction) {
                                _deleteBet(item['id']);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      // Type Badge
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Text(
                                            item['type'].toString(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  '${item['game']} | ${item['number']}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: Color(0xFF1E293B),
                                                  ),
                                                ),
                                                Text(
                                                  '₹${item['total']}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 15,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Qty: ${item['count']} × ₹${item['amount']}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                                if (item['user'] != null &&
                                                    item['user'] != 'Forwarded')
                                                  Text(
                                                    item['user'],
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.blueGrey.shade700,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              dateStr,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.red, size: 20),
                                        onPressed: () => _confirmDelete(
                                          item['id'],
                                          item['number'].toString(),
                                          item['type'].toString(),
                                          item['count'] as int,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
