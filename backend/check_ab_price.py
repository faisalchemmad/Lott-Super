import sys
p = r'd:\Gemini\Android\Lott_super\frontend\lib\views\betting_screen.dart'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()

# Find the AB/BC/AC tab handling - where unit price is set for AB/BC/AC
# Look for 'AB' type with unitPrice assignment
idx = c.find('AB_BC_AC')
while idx != -1:
    print(f"=== AB_BC_AC at {idx} ===")
    sys.stdout.buffer.write(c[max(0,idx-200):idx+400].encode('utf-8'))
    print("\n---\n")
    idx = c.find('AB_BC_AC', idx+10)
    if idx > 25000:
        break
