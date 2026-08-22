import sys

p = r'd:\Gemini\Android\Lott_super\frontend\lib\views\sales_report_detail_screen.dart'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()

start_str = '  Widget _buildInvoiceList(List invoices) {'
start_idx = c.find(start_str)

end_str = '    return ListView.builder('
end_idx = c.find(end_str, start_idx)

new_code = '''  Widget _buildInvoiceList(List invoices) {
    if (widget.fullView) {
      return Column(
        children: invoices.map((inv) {
          final items = inv['items'] ?? [];
          final createdAt = DateTime.parse(inv['created_at']);
          final dateStr = DateFormat('yyyy-MM-dd').format(createdAt);
          final timeStr = DateFormat('HH:mm:ss').format(createdAt);
          final displayId = inv['invoice_id'].toString();

          return Container(
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
          );
        }).toList(),
      );
    }

'''

c = c[:start_idx] + new_code + c[end_idx:]
with open(p, 'w', encoding='utf-8') as f:
    f.write(c)
print("Patched successfully!")
