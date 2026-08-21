"
p = 'd:/Gemini/Android/Lott_super/frontend/lib/views/betting_screen.dart'
with open(p, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
i = 0
while i < len(lines):
    new_lines.append(lines[i])
    if '_draftBets.insert(0, {' in lines[i]:
        has_state = False
        for j in range(i+1, min(i+10, len(lines))):
            if 'state' in lines[j]:
                has_state = True
                break
        
        if not has_state:
            # find price and insert before it
            j = i + 1
            while j < i + 10:
                if 'price' in lines[j] and 'net_price' not in lines[j]:
                    new_lines.append(chr(32)*18 + \
state
:
_selectedStateCode
\\n\)
                    break
                j += 1
    i += 1

with open(p, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
print('SUCCESS')
"
