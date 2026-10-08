with open(r"d:\MT5_Tester\m3_20_diag.htm", "r", encoding="utf-16", errors="ignore") as f:
    text = f.read()

import re
matches = re.findall(r'<tr[^>]*>(.*?)</tr>', text, re.DOTALL)
print("Total table rows:", len(matches))
for row in matches:
    clean = re.sub(r'<[^>]+>', ' ', row).strip()
    clean = re.sub(r'\s+', ' ', clean)
    if any(k in clean.lower() for k in ['deal', 'order', 'profit', 'balance', 'stop out', 'margin']):
        print(clean)
