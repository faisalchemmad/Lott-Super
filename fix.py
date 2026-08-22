import glob, os

files = glob.glob('d:/Gemini/Android/Lott_super/frontend/lib/views/*report*screen.dart')
for f in files:
    with open(f, 'r', encoding='utf-8') as fp:
        c = fp.read()
    if "')," in c:
        lines = c.split('\n')
        new_lines = []
        for line in lines:
            if line.strip() == "'),":
                print('Found in', f)
                continue
            new_lines.append(line)
        with open(f, 'w', encoding='utf-8') as fp:
            fp.write('\n'.join(new_lines))
