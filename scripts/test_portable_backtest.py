import subprocess
import os
import time

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"

ini_path = os.path.join(DATA_FOLDER, "test_portable.ini")
rep_name = "test_portable_rep"
rep_path = os.path.join(DATA_FOLDER, f"{rep_name}.htm")

if os.path.exists(rep_path):
    try: os.remove(rep_path)
    except: pass

ini_text = f"""[Common]
Login=472929

[Tester]
Expert=Advisors\\ExpertMACD
Symbol=EURUSD
Period=H1
Model=1
FromDate=2024.01.01
ToDate=2024.01.20
Deposit=1000
Currency=USD
Leverage=1:100
ExecutionMode=0
Optimization=0
Report={rep_name}
ReplaceReport=1
ShutdownTerminal=1
Visual=0
"""

with open(ini_path, "w", encoding="utf-8") as f:
    f.write(ini_text)

print("Starting portable terminal tester...")
t0 = time.time()
p = subprocess.run([TESTER_EXE, "/portable", f"/config:{ini_path}"], capture_output=True, text=True, timeout=90)
elapsed = time.time() - t0
print(f"Portable tester finished in {elapsed:.2f}s with code {p.returncode}")
print("Report generated:", os.path.exists(rep_path))

if os.path.exists(rep_path):
    print("Report size:", os.path.getsize(rep_path))
    with open(rep_path, "r", encoding="utf-16", errors="ignore") as f:
        print("Report preview:\n", f.read()[:500])
else:
    t_logs = os.path.join(DATA_FOLDER, "Tester", "logs")
    if os.path.exists(t_logs):
        files = sorted(os.listdir(t_logs), reverse=True)
        print("Tester logs:", files[:3])
        if files:
            with open(os.path.join(t_logs, files[0]), "r", encoding="utf-16", errors="ignore") as lf:
                print("Latest log snippet:\n", lf.read()[-500:])
