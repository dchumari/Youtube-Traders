import sys
import os
sys.path.append(r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\scripts")
from run_16_windows_100_and_20 import execute_window_backtest, WINDOWS

win = WINDOWS["M3"]
print("Testing M3 on $100:")
r100 = execute_window_backtest("M3", win, deposit=100.0, leverage="1:100")
print(r100)

print("\nTesting M3 on $20:")
r20 = execute_window_backtest("M3", win, deposit=20.0, leverage="1:500")
print(r20)
