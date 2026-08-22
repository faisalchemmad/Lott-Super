p = r'd:\Gemini\Android\Lott_super\backend\core\views.py'
with open(p, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix the broken regex - line 2399 contains a literal newline inside the string
old_fragment = "            comps = re.split(r'[,\\s\n]+', game_result.complimentary_numbers.strip())"
new_fragment = "            comps = re.split(r'[,\\s\\n]+', game_result.complimentary_numbers.strip())"

if old_fragment in content:
    content = content.replace(old_fragment, new_fragment, 1)
    print("Fixed first occurrence")
else:
    print("NOT FOUND - trying raw approach")
    # Try direct byte replacement  
    old_bytes = b"            comps = re.split(r'[,\\s\n]+', game_result.complimentary_numbers.strip())"
    new_bytes = b"            comps = re.split(r'[,\\s\\n]+', game_result.complimentary_numbers.strip())"
    content_bytes = content.encode('utf-8')
    if old_bytes in content_bytes:
        content_bytes = content_bytes.replace(old_bytes, new_bytes, 1)
        content = content_bytes.decode('utf-8')
        print("Fixed via bytes")
    else:
        print("Also not found as bytes")

# Count occurrences and fix second one too
count = content.count("comps = re.split(r'[,\\s\n")
print(f"Remaining broken occurrences: {count}")

with open(p, 'w', encoding='utf-8') as f:
    f.write(content)
print("Done")
