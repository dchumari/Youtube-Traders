import subprocess
import os
import time

TERMINAL_EXE = r"C:\Program Files\MetaTrader 5\terminal64.exe"
DATA_FOLDER = r"C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075"

ini_path = os.path.join(DATA_FOLDER, "test_run.ini")
rep_name = "test_run_rep"
rep_path = os.path.join(DATA_FOLDER, f"{rep_name}.htm")

ini_text = f"""[Common]
Login=472929

[Tester]
Expert=Advisors\\ExpertMACD
Symbol=EURUSD
Period=M15
Model=1
FromDate=2024.01.01
ToDate=2024.01.10
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

print("Starting terminal...")
t0 = time.time()
res = subprocess.run([TERMINAL_EXE, f"/config:{ini_path}"], capture_output=True, text=True, timeout=60)
print(f"Terminal exited in {time.time()-t0:.2f}s with code {res.returncode}")
print("Stdout:", res.stdout)
print("Stderr:", res.stderr)
print("Report exists?", os.path.exists(rep_path))

# Check logs in Tester/logs
t_logs = os.path.join(DATA_FOLDER, "Tester", "logs")
if os.path.exists(t_logs):
    files = sorted(os.listdir(t_logs), reverse=True)
    print("Recent tester logs:", files[:3])
    if files:
        latest = os.path.join(t_logs, files[0])
        print(f"--- Content of {files[0]} ---")
        try:
            with open(latest, "r", encoding="utf-16", errors="ignore") as lf:
                print(lf.read()[-1000:])
        except Exception as e:
            print("Err reading log:", e)
