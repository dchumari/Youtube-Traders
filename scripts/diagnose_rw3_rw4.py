import subprocess
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

# Let's inspect what happens in the tester log during RW3 and RW4
LOG_DIR = r"C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\8547D8E8CD54EE935BB2ECEA51CE4672\Tester\logs"
if os.path.exists(LOG_DIR):
    logs = sorted(os.listdir(LOG_DIR))
    if logs:
        latest = os.path.join(LOG_DIR, logs[-1])
        print(f"Inspecting latest log: {latest}", flush=True)
        try:
            with open(latest, 'r', encoding='utf-16', errors='ignore') as f:
                lines = f.readlines()
        except:
            with open(latest, 'r', encoding='utf-8', errors='ignore') as f:
                lines = f.readlines()
        
        matches = [line.strip() for line in lines if "INVERTED" in line or "QM" in line or "ORB" in line or "trade" in line.lower()]
        print(f"Total matching lines in log: {len(matches)}")
        for l in matches[-25:]:
            print("  ", l)
