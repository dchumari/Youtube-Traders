import os
import sys
import time
import subprocess
import logging
from pathlib import Path
import urllib.request

# Configuration
TERMINAL_EXE = Path(r"C:\Program Files\MetaTrader 5\terminal64.exe")
DATA_FOLDER = Path(r"C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075")
CHECK_INTERVAL_SECONDS = 15
INTERNET_CHECK_HOST = "https://www.google.com"

# Logging setup
LOG_FILE = Path(__file__).resolve().parent / "watchdog.log"
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE, encoding="utf-8"),
        logging.StreamHandler(sys.stdout)
    ]
)

def is_mt5_running():
    try:
        output = subprocess.check_output(
            ["tasklist", "/FI", "IMAGENAME eq terminal64.exe", "/FO", "CSV"],
            text=True,
            creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
        )
        return "terminal64.exe" in output.lower()
    except Exception as e:
        logging.error(f"Error checking MT5 process: {e}")
        return False

def check_internet():
    try:
        urllib.request.urlopen(INTERNET_CHECK_HOST, timeout=5)
        return True
    except Exception:
        return False

def launch_mt5(minimized=True):
    if not TERMINAL_EXE.exists():
        logging.error(f"MT5 executable not found at: {TERMINAL_EXE}")
        return False
    try:
        logging.info(f"Launching MT5 terminal in background (minimized={minimized}): {TERMINAL_EXE}")
        startupinfo = None
        if os.name == "nt" and minimized:
            startupinfo = subprocess.STARTUPINFO()
            startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
            startupinfo.wShowWindow = 6 # SW_MINIMIZE (runs in background/taskbar)
        subprocess.Popen([str(TERMINAL_EXE)], cwd=str(TERMINAL_EXE.parent), startupinfo=startupinfo, shell=False)
        return True
    except Exception as e:
        logging.error(f"Failed to launch MT5: {e}")
        return False

def main():
    logging.info("==================================================")
    logging.info("MT5 24/7 Autonomous Watchdog Engine Started")
    logging.info(f"Target Terminal: {TERMINAL_EXE}")
    logging.info(f"Check Interval: {CHECK_INTERVAL_SECONDS} seconds")
    logging.info("==================================================")

    restarts = 0
    was_offline = False

    while True:
        try:
            # 1. Internet Check
            online = check_internet()
            if not online:
                if not was_offline:
                    logging.warning("⚠️ Internet connection lost! Waiting for network recovery...")
                    was_offline = True
            else:
                if was_offline:
                    logging.info("✅ Internet connection restored!")
                    was_offline = False

            # 2. MT5 Process Check
            running = is_mt5_running()
            if not running:
                restarts += 1
                logging.warning(f"🚨 MT5 terminal is NOT running! Restart attempt #{restarts}...")
                launch_mt5()
                # Wait 10 seconds for process initialization
                time.sleep(10)
            else:
                # Terminal is healthy
                pass

        except Exception as e:
            logging.error(f"Unexpected error in watchdog loop: {e}")

        time.sleep(CHECK_INTERVAL_SECONDS)

if __name__ == "__main__":
    main()
