import sys
import re

p = r'd:\Gemini\Android\Lott_super\frontend\lib\views\publish_result_screen.dart'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()

pattern = r"_buildPrizeInput\('1st Prize', _p1Controller, AppColors\.primary, true,\s*_resultType == 'TN' \? 4 : 3\),"
replacement = """_buildPrizeInput('1st Prize', _p1Controller, AppColors.primary, true,
              _resultType == 'TN' ? 4 : 3, (val) {
            if (_resultType == 'TN') {
              _p2Controller.text = val.length >= 3 ? val.substring(val.length - 3) : val;
              _p3Controller.text = val.length >= 2 ? val.substring(val.length - 2) : val;
              _p4Controller.text = val.length >= 1 ? val.substring(val.length - 1) : val;
            }
          }),"""

c = re.sub(pattern, replacement, c)

with open(p, 'w', encoding='utf-8') as f:
    f.write(c)
print('Regex replaced successfully!')
