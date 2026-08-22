
p = 'd:/Gemini/Android/Lott_super/frontend/lib/views/sales_report_detail_screen.dart'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()

import re

# We will replace the whole return Container(...) block inside the fullView map

start_str = '          return Container(\\n            margin: const EdgeInsets.only(bottom: 12),'
start_idx = c.find(start_str)

end_idx = c.find('                children: [', start_idx)

old_code = c[start_idx:end_idx]

new_code = '''          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                            Text('INV-',
                                style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900)),
                          ],
                        ),
                        Text('  ',
                            style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(inv['user__username'] ?? '',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                        Row(
                          children: [
                            Text('Qty: ',
                                style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                  '₹',
                                  style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
'''

c = c.replace(old_code, new_code)

with open(p, 'w', encoding='utf-8') as f:
    f.write(c)

