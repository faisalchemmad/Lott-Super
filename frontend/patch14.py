import sys

p = r'd:\Gemini\Android\Lott_super\frontend\lib\views\publish_result_screen.dart'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()

# 1. Update state variable
c = c.replace('int _digitCount = 3;', "String _resultType = 'KL';")

# 2. Update initState guessing
init_old = '''_selectedGameId = widget.resultData!['game'];
      String winNum = widget.resultData!['winning_number'] ?? '';
      if (winNum.length == 4) {
        _digitCount = 4;
      }'''
init_new = '''_selectedGameId = widget.resultData!['game'];
      String winNum = widget.resultData!['winning_number'] ?? '';
      if (winNum.length == 4) {
        _resultType = 'TN';
      }'''
c = c.replace(init_old, init_new)

# 3. Update _handlePaste
paste_old = '''  void _handlePaste() async {
    ClipboardData? data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null) {
      String text = data.text!.trim();
      // Split by comma, space or newline and take first 30 numbers of 3 digits
      List<String> parts =
          text.split(RegExp(r'[,\s\n]+')).where((e) => e.length == _digitCount).toList();

      if (parts.length >= 30) {
        _compController.text = parts.take(30).join(', ');
      } else {
        _compController.text = parts.join(', ');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Found only ${parts.length} $_digitCount-digit numbers.')));
      }
    }
  }'''
paste_new = '''  void _handlePaste() async {
    ClipboardData? data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null) {
      String text = data.text!.trim();
      // Split by comma, space or newline and take first 30 numbers of 3 digits
      List<String> parts =
          text.split(RegExp(r'[,\s\n]+')).where((e) => e.length == 3).toList();

      if (parts.length >= 30) {
        _compController.text = parts.take(30).join(', ');
      } else {
        _compController.text = parts.join(', ');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Found only ${parts.length} 3-digit numbers.')));
      }
    }
  }'''
c = c.replace(paste_old, paste_new)

# 4. Update _handlePasteAll
pasteall_old = '''  void _handlePasteAll() async {
    ClipboardData? data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null) {
      String text = data.text!.trim();
      List<String> parts =
          text.split(RegExp(r'[,\s\n]+')).where((e) => e.length == _digitCount).toList();

      if (parts.isNotEmpty) {
        setState(() {
          if (parts.length >= 1) _p1Controller.text = parts[0];
          if (parts.length >= 2) _p2Controller.text = parts[1];
          if (parts.length >= 3) _p3Controller.text = parts[2];
          if (parts.length >= 4) _p4Controller.text = parts[3];
          if (parts.length >= 5) _p5Controller.text = parts[4];

          if (parts.length > 5) {
            _compController.text = parts.skip(5).take(30).join(', ');
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Auto-filled ${parts.length > 35 ? 35 : parts.length} numbers.')));
      }
    }
  }'''
pasteall_new = '''  void _handlePasteAll() async {
    ClipboardData? data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null) {
      String text = data.text!.trim();
      List<String> rawParts = text.split(RegExp(r'[,\s\n]+')).where((e) => e.isNotEmpty).toList();

      if (rawParts.isNotEmpty) {
        setState(() {
          if (_resultType == 'TN') {
            if (rawParts.length >= 1 && rawParts[0].length == 4) _p1Controller.text = rawParts[0];
            if (rawParts.length >= 2 && rawParts[1].length == 3) _p2Controller.text = rawParts[1];
            if (rawParts.length >= 3 && rawParts[2].length == 2) _p3Controller.text = rawParts[2];
            if (rawParts.length >= 4 && rawParts[3].length == 1) _p4Controller.text = rawParts[3];
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Auto-filled TN numbers.')));
          } else {
            List<String> parts = rawParts.where((e) => e.length == 3).toList();
            if (parts.isNotEmpty) {
              if (parts.length >= 1) _p1Controller.text = parts[0];
              if (parts.length >= 2) _p2Controller.text = parts[1];
              if (parts.length >= 3) _p3Controller.text = parts[2];
              if (parts.length >= 4) _p4Controller.text = parts[3];
              if (parts.length >= 5) _p5Controller.text = parts[4];

              if (parts.length > 5) {
                _compController.text = parts.skip(5).take(30).join(', ');
              }
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Auto-filled ${parts.length > 35 ? 35 : parts.length} numbers.')));
            }
          }
        });
      }
    }
  }'''
c = c.replace(pasteall_old, pasteall_new)

# 5. Update body in build()
build_old = '''                  _buildPrizeFields(),
                  const SizedBox(height: 24),
                  _buildCompField(),
                  const SizedBox(height: 32),'''
build_new = '''                  _buildPrizeFields(),
                  if (_resultType == 'KL') ...[
                    const SizedBox(height: 24),
                    _buildCompField(),
                  ],
                  const SizedBox(height: 32),'''
c = c.replace(build_old, build_new)

# 6. Update _buildDigitToggle
toggle_old = '''  Widget _buildDigitToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DIGITS',
            style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDigitOption(3),
              Container(width: 1, color: Colors.black.withOpacity(0.05)),
              _buildDigitOption(4),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDigitOption(int digit) {
    bool isSelected = _digitCount == digit;
    return GestureDetector(
      onTap: () {
        setState(() {
          _digitCount = digit;
          // Clear current inputs when switching digit count
          _p1Controller.clear();
          _p2Controller.clear();
          _p3Controller.clear();
          _p4Controller.clear();
          _p5Controller.clear();
          _compController.clear();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        alignment: Alignment.center,
        child: Text(
          '$digit',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }'''
toggle_new = '''  Widget _buildDigitToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TYPE',
            style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDigitOption('KL'),
              Container(width: 1, color: Colors.black.withOpacity(0.05)),
              _buildDigitOption('TN'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDigitOption(String type) {
    bool isSelected = _resultType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _resultType = type;
          // Clear current inputs when switching type
          _p1Controller.clear();
          _p2Controller.clear();
          _p3Controller.clear();
          _p4Controller.clear();
          _p5Controller.clear();
          _compController.clear();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        alignment: Alignment.center,
        child: Text(
          type,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }'''
c = c.replace(toggle_old, toggle_new)

# 7. Update _buildPrizeFields
fields_old = '''          _buildPrizeInput('1st Prize', _p1Controller, AppColors.primary, true),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.black12),
          ),
          _buildPrizeInput('2nd Prize', _p2Controller, Colors.grey[700]!),
          _buildPrizeInput('3rd Prize', _p3Controller, Colors.grey[700]!),
          _buildPrizeInput('4th Prize', _p4Controller, Colors.grey[700]!),
          _buildPrizeInput('5th Prize', _p5Controller, Colors.grey[700]!),'''
fields_new = '''          _buildPrizeInput('1st Prize', _p1Controller, AppColors.primary, true, _resultType == 'TN' ? 4 : 3),
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
c = c.replace(fields_old, fields_new)

# 8. Update _buildPrizeInput signature
input_old = '''  Widget _buildPrizeInput(
      String label, TextEditingController controller, Color color,
      [bool isFirst = false]) {'''
input_new = '''  Widget _buildPrizeInput(
      String label, TextEditingController controller, Color color,
      [bool isFirst = false, int maxLength = 3]) {'''
c = c.replace(input_old, input_new)

# 9. Update maxLength in _buildPrizeInput
input_len_old = '''maxLength: _digitCount,'''
input_len_new = '''maxLength: maxLength,'''
c = c.replace(input_len_old, input_len_new)


with open(p, 'w', encoding='utf-8') as f:
    f.write(c)
print('Patched successfully!')
