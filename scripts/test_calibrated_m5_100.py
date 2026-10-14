import subprocess, os, re, json, time, sys
sys.stdout.reconfigure(encoding='utf-8')
from test_model5_100usd import run_single_test, RANDOM_4_WINDOWS

base_inputs = {
    "InpCoreModel": "5",
    "InpHorizonMode": "0",
    "InpMagicNumber": "889205",
    "InpBaseLotSize": "0.01",
    "InpEquityStepSprint": "35.0",
    "InpEquityStepMonthly": "50.0",
    "InpMaxLotCap": "0.15",
    "InpBaseStopLossPoints": "200",
    "InpSpamTicketsCount": "2",
    "InpTP1Points": "200",
    "InpTP2Points": "500",
    "InpTP3Points": "800",
    "InpTP4Points": "1200",
    "InpTP5Points": "1800",
    "InpEnablePyramiding": "0",
    "InpMaxPyramidLayers": "1",
    "InpReloadStepPoints": "300",
    "InpEnableDumpAndFlip": "0",
    "InpDumpWickRatio": "0.45",
    "InpSwingLookback": "24",
    "InpTrendlinePoints": "3",
    "InpMinSweepPoints": "100",
    "InpMinWickRejection": "0.35",
    "InpEMATrendPeriod": "50",
    "InpVolumeSurgeMult": "1.5",
    "InpUseSessionFilter": "1",
    "InpLondonStartHour": "7",
    "InpLondonEndHour": "11",
    "InpNYStartHour": "12",
    "InpNYEndHour": "18",
    "InpGMTOffset": "3",
    "InpMaxDailyTrades": "2",
    "InpMinTradeCooldownMin": "90",
    "InpEnableDailyDoubleLockout": "1",
    "InpDailyTargetPct": "100.0",
    "InpMinATRPoints": "120.0",
    "InpEnableWeeklyTargetLockout": "1",
    "InpWeeklyTargetPct": "50.0",
    "InpEnableWeeklyTrailingShield": "1",
    "InpWeeklyMaxGivebackPct": "30.0",
    "InpEnableVisuals": "0",
    "InpApplyDraculaTheme": "0"
}

print("=== Testing Calibrated Model 5 on $100 across 4 Random Weeks ===", flush=True)
total_profit = 0.0
for w_name, w_info in RANDOM_4_WINDOWS.items():
    res = run_single_test(f"m5_cal_100_{w_name[:3]}", w_info["from"], w_info["to"], 100.0, 400, base_inputs)
    print(f"[{w_name}] Net: ${res['net_profit']:+.2f} ({res['roi_pct']:+.1f}%) | Trades: {res['trades']} | PF: {res['profit_factor']:.2f} | DD: {res['max_dd_pct']:.1f}%", flush=True)
    total_profit += res['net_profit']
print(f"Cumulative Net Profit: ${total_profit:+.2f} ({total_profit:+.1f}%)", flush=True)
