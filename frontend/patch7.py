import sys

p = r'd:\Gemini\Android\Lott_super\frontend\lib\views\sales_report_detail_screen.dart'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()

start_str = '  Widget _buildInvoiceList(List invoices) {'
start_idx = c.find(start_str)

end_str = '    return ListView.builder('
end_idx = c.find(end_str, start_idx)

# Find the end of ListView.builder
# It ends right before `  Widget _buildInvoiceDetail(` or `  Widget _buildDetailRow(`
end_listview = c.find('  Widget ', end_idx + 10)
if end_listview == -1:
    end_listview = c.rfind('}') - 5

new_code = '''
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
            content: const Text('Are you sure you want to delete this invoice?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        try {
          final success = await Provider.of<ApiService>(context, listen: false).deleteInvoice(invoiceId);
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invoice deleted successfully')),
            );
            setState(() {
              if (_currentReportData['invoices'] != null) {
                (_currentReportData['invoices'] as List).removeWhere((i) => i['invoice_id'].toString() == invoiceId);
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

          return _buildDismissibleWrapper(inv, Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                            const Icon(Icons.receipt_rounded, size: 16, color: AppColors.primary),
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
                            Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey[400]),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                  '₹${(widget.userRole == "SUPER_ADMIN" || widget.userRole == "ADMIN" || widget.userRole == "AGENT" || widget.userRole == "DEALER") ? inv['net'] : inv['amount']}',
                                  style: const TextStyle(
                                      color: Color(0xFF10B981),
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
                  Container(color: Colors.white, child: Column(children: [
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
                            child: Text(item['number'].toString(),
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
                                  (item['count'] > 0 ? (item['net'] / item['count']) : 0.0)
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

        return _buildDismissibleWrapper(inv, Container(
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
                        'TOTAL',
                        style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${(widget.userRole == "SUPER_ADMIN" || widget.userRole == "ADMIN" || widget.userRole == "AGENT" || widget.userRole == "DEALER") ? inv['net'] : inv['amount']}',
                        style: const TextStyle(
                            color: Color(0xFF10B981),
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
'''

c = c[:start_idx] + new_code + c[end_listview:]
with open(p, 'w', encoding='utf-8') as f:
    f.write(c)
print("Patched successfully!")
