import sys

p = r'd:\Gemini\Android\Lott_super\frontend\lib\views\publish_result_screen.dart'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()

# Replace _buildPrizeFields
fields_old = '''          _buildPrizeInput('1st Prize', _p1Controller, AppColors.primary, true, _resultType == 'TN' ? 4 : 3),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.black12),
          ),
          _buildPrizeInput('2nd Prize', _p2Controller, Colors.grey[700]!, false, 3),
          if (_resultType == 'TN') ...[
            _buildPrizeInput('3rd Prize', _p3Controller, Colors.grey[700]!, false, 2),
            _buildPrizeInput('4th Prize', _p4Controller, Colors.grey[700]!, false, 1),
          ] else ...[
            _buildPrizeInput('3rd Prize', _p3Controller, Colors.grey[700]!, false, 3),
            _buildPrizeInput('4th Prize', _p4Controller, Colors.grey[700]!, false, 3),
            _buildPrizeInput('5th Prize', _p5Controller, Colors.grey[700]!, false, 3),
          ],'''
fields_new = '''          _buildPrizeInput('1st Prize', _p1Controller, AppColors.primary, true, _resultType == 'TN' ? 4 : 3, (val) {
            if (_resultType == 'TN') {
              _p2Controller.text = val.length >= 3 ? val.substring(val.length - 3) : val;
              _p3Controller.text = val.length >= 2 ? val.substring(val.length - 2) : val;
              _p4Controller.text = val.length >= 1 ? val.substring(val.length - 1) : val;
            }
          }),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.black12),
          ),
          _buildPrizeInput('2nd Prize', _p2Controller, Colors.grey[700]!, false, 3),
          if (_resultType == 'TN') ...[
            _buildPrizeInput('3rd Prize', _p3Controller, Colors.grey[700]!, false, 2),
            _buildPrizeInput('4th Prize', _p4Controller, Colors.grey[700]!, false, 1),
          ] else ...[
            _buildPrizeInput('3rd Prize', _p3Controller, Colors.grey[700]!, false, 3),
            _buildPrizeInput('4th Prize', _p4Controller, Colors.grey[700]!, false, 3),
            _buildPrizeInput('5th Prize', _p5Controller, Colors.grey[700]!, false, 3),
          ],'''
if fields_old in c:
    c = c.replace(fields_old, fields_new)
else:
    print("Could not find fields_old")


# Replace _buildPrizeInput signature
input_old = '''  Widget _buildPrizeInput(
      String label, TextEditingController controller, Color color,
      [bool isFirst = false, int maxLength = 3]) {'''
input_new = '''  Widget _buildPrizeInput(
      String label, TextEditingController controller, Color color,
      [bool isFirst = false, int maxLength = 3, void Function(String)? onChanged]) {'''
if input_old in c:
    c = c.replace(input_old, input_new)
else:
    print("Could not find input_old")


# Add onChanged to TextField
textfield_old = '''              child: TextField(
                controller: controller,
                style: TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2),
                maxLength: maxLength,
                keyboardType: TextInputType.number,'''
textfield_new = '''              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2),
                maxLength: maxLength,
                keyboardType: TextInputType.number,'''
if textfield_old in c:
    c = c.replace(textfield_old, textfield_new)
else:
    print("Could not find textfield_old")

with open(p, 'w', encoding='utf-8') as f:
    f.write(c)
print('Patched successfully!')
