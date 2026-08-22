import sys

p = r'd:\Gemini\Android\Lott_super\frontend\lib\views\publish_result_screen.dart'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()

# Add _digitCount to state
c = c.replace('int? _selectedGameId;', 'int? _selectedGameId;\n  int _digitCount = 3;')

# Guess digitCount in initState
init_state_old = '''_selectedGameId = widget.resultData!['game'];'''
init_state_new = '''_selectedGameId = widget.resultData!['game'];
      String winNum = widget.resultData!['winning_number'] ?? '';
      if (winNum.length == 4) {
        _digitCount = 4;
      }'''
c = c.replace(init_state_old, init_state_new)

# Update _handlePaste
c = c.replace("e.length == 3", "e.length == _digitCount")
c = c.replace("3-digit numbers", "$_digitCount-digit numbers")

# Update _buildSelectionHeader
header_old = '''Widget _buildSelectionHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildGameDropdown(),
          const SizedBox(height: 16),
          _buildDateSelector(),
        ],
      ),
    );
  }'''

header_new = '''Widget _buildSelectionHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildGameDropdown()),
              const SizedBox(width: 12),
              _buildDigitToggle(),
            ],
          ),
          const SizedBox(height: 16),
          _buildDateSelector(),
        ],
      ),
    );
  }

  Widget _buildDigitToggle() {
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
c = c.replace(header_old, header_new)

# Update _buildPrizeInput
c = c.replace('maxLength: 3,', 'maxLength: _digitCount,')

with open(p, 'w', encoding='utf-8') as f:
    f.write(c)
print('Patched successfully!')
