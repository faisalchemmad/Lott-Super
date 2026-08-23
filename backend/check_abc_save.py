import sys
p = r'd:\Gemini\Android\Lott_super\frontend\lib\views\betting_screen.dart'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()

# Find where A/B/C type bets are added to draft
idx = c.find("'type': 'A'")
if idx == -1:
    idx = c.find("type: 'A'")
if idx != -1:
    sys.stdout.buffer.write(c[max(0,idx-300):idx+500].encode('utf-8'))
else:
    print("Not found - searching for ABC save logic...")
    idx = c.find("_addAbcBet")
    if idx != -1:
        sys.stdout.buffer.write(c[max(0,idx-100):idx+600].encode('utf-8'))
    else:
        # Find draft insert for ABC
        idx = c.find("'ABC'")
        if idx != -1:
            sys.stdout.buffer.write(c[max(0,idx-300):idx+500].encode('utf-8'))

print("\n\n===SEARCH FOR AB TYPE===")
idx = c.find("'type': 'AB'")
if idx != -1:
    sys.stdout.buffer.write(c[max(0,idx-300):idx+500].encode('utf-8'))
