import sys

p = r'd:\Gemini\Android\Lott_super\frontend\lib\views\sales_report_detail_screen.dart'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()

old_code = '''                Expanded(
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
                const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
              ],
            ),'''

new_code = '''                Expanded(
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
            ),'''

if old_code in c:
    c = c.replace(old_code, new_code)
    with open(p, 'w', encoding='utf-8') as f:
        f.write(c)
    print("Patched correctly!")
else:
    print("Could not find old_code!")
