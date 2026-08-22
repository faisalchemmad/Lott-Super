import sys

p = r'd:\Gemini\Android\Lott_super\frontend\lib\views\sales_report_detail_screen.dart'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()

func_idx = c.find('Widget _buildInvoiceList(List invoices) {')
if func_idx == -1:
    print("Function not found!")
    sys.exit(1)

start_str = '          return Container(\n            margin: const EdgeInsets.only(bottom: 12),'
start_idx = c.find(start_str, func_idx)

end_str = '                children: ['
end_idx = c.find(end_str, start_idx)

if start_idx != -1 and end_idx != -1:
    new_code = '''          return Container(
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
'''
    
    c = c[:start_idx] + new_code + c[end_idx:]
    with open(p, 'w', encoding='utf-8') as f:
        f.write(c)
    print("Patched successfully!")
else:
    print("Not found", start_idx, end_idx)
