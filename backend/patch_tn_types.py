p = r'd:\Gemini\Android\Lott_super\backend\core\views.py'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()

# In _calculate_winners, there are TWO functions. In both, find the AB/BC/AC handling
# and add TN-A/TN-B/TN-C/TN-AB/TN-BC/TN-AC types

old_block = "                elif b_type in ['AB', 'BC', 'AC', 'A', 'B', 'C']:\r\n                    if tier_name != \"1ST PRIZE\":\r\n                        continue\r\n                    \r\n                    base_win = win_num[-3:] if len(win_num) >= 3 else win_num\r\n                    target = \"\"\r\n                    if len(base_win) >= 3:\r\n                        if b_type == 'AB': target = base_win[0:2]\r\n                        elif b_type == 'BC': target = base_win[1:3]\r\n                        elif b_type == 'AC': target = base_win[0] + base_win[2]\r\n                        elif b_type == 'A': target = base_win[0]\r\n                        elif b_type == 'B': target = base_win[1]\r\n                        elif b_type == 'C': target = base_win[2]\r\n                    elif len(base_win) == 2:\r\n                        if b_type == 'AB': target = base_win\r\n                        elif b_type == 'A': target = base_win[0]\r\n                        elif b_type == 'B': target = base_win[1]\r\n                    elif len(base_win) == 1:\r\n                        if b_type == 'A': target = base_win\r\n                    \r\n                    if target and b_num == target:\r\n                        match = True\r\n                        if state == 'TN':\r\n                            if b_type in ['AB', 'BC', 'AC']: p, c = float(u.tn_prize_ab_bc_ac), 0.0\r\n                            else: p, c = float(u.tn_prize_abc), 0.0\r\n                        else:\r\n                            if b_type in ['AB', 'BC', 'AC']: p, c = float(u.prize_ab_bc_ac_1), float(u.comm_ab_bc_ac_1)\r\n                            else: p, c = float(u.prize_abc_1), float(u.comm_abc_1)"

new_block = "                elif b_type in ['AB', 'BC', 'AC', 'A', 'B', 'C', 'TN-AB', 'TN-BC', 'TN-AC', 'TN-A', 'TN-B', 'TN-C']:\r\n                    if tier_name != \"1ST PRIZE\":\r\n                        continue\r\n                    \r\n                    base_win = win_num[-3:] if len(win_num) >= 3 else win_num\r\n                    target = \"\"\r\n                    # Normalize type for matching (strip TN- prefix)\r\n                    norm_type = b_type.replace('TN-', '')\r\n                    is_tn_type = b_type.startswith('TN-')\r\n                    if len(base_win) >= 3:\r\n                        if norm_type == 'AB': target = base_win[0:2]\r\n                        elif norm_type == 'BC': target = base_win[1:3]\r\n                        elif norm_type == 'AC': target = base_win[0] + base_win[2]\r\n                        elif norm_type == 'A': target = base_win[0]\r\n                        elif norm_type == 'B': target = base_win[1]\r\n                        elif norm_type == 'C': target = base_win[2]\r\n                    elif len(base_win) == 2:\r\n                        if norm_type == 'AB': target = base_win\r\n                        elif norm_type == 'A': target = base_win[0]\r\n                        elif norm_type == 'B': target = base_win[1]\r\n                    elif len(base_win) == 1:\r\n                        if norm_type == 'A': target = base_win\r\n                    \r\n                    if target and b_num == target:\r\n                        match = True\r\n                        if is_tn_type or state == 'TN':\r\n                            if norm_type in ['AB', 'BC', 'AC']: p, c = float(u.tn_prize_ab_bc_ac), 0.0\r\n                            else: p, c = float(u.tn_prize_abc), 0.0\r\n                        else:\r\n                            if norm_type in ['AB', 'BC', 'AC']: p, c = float(u.prize_ab_bc_ac_1), float(u.comm_ab_bc_ac_1)\r\n                            else: p, c = float(u.prize_abc_1), float(u.comm_abc_1)"

count_replaced = c.count(old_block)
print(f"Found {count_replaced} occurrences to replace")

if count_replaced > 0:
    c = c.replace(old_block, new_block)
    with open(p, 'w', encoding='utf-8') as f:
        f.write(c)
    print("Done!")
else:
    # Try with \n instead of \r\n
    old_block2 = old_block.replace('\r\n', '\n')
    new_block2 = new_block.replace('\r\n', '\n')
    count_replaced2 = c.count(old_block2)
    print(f"Found {count_replaced2} with \\n")
    if count_replaced2 > 0:
        c = c.replace(old_block2, new_block2)
        with open(p, 'w', encoding='utf-8') as f:
            f.write(c)
        print("Done!")
    else:
        print("Block not found - need manual check")
