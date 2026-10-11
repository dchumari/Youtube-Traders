import sys
sys.stdout.reconfigure(encoding='utf-8')
from benchmark_calibrated_4_windows import run_backtest

base_cfg = {
    "InpSessionFilter": 1,
    "InpExecutionEngine": 0,
    "InpBaseLotSize": 0.01,
    "InpEquityPerMinLot": 35.0,
    "InpMaxLotCap": 0.50,
    "InpStopLossPoints": 250,
    "InpSpamTicketsCount": 5,
    "InpTP1Points": 200,
    "InpTP2Points": 350,
    "InpTP3Points": 600,
    "InpTP4Points": 1000,
    "InpTP5Points": 1600,
    "InpEnableTraceback": "false",
    "InpEnablePyramiding": "true",
    "InpReloadStepPoints": 350,
    "InpMaxPyramidLayers": 3,
    "InpReloadTicketsCount": 3,
    "InpEnableDumpAndFlip": "false",
    "InpEnableVolumeClimax": "false",
    "InpEnableFlipMilestone": "true",
    "InpTargetEquity": 1000.0,
    "InpLookbackBars": 30,
    "InpMinSweepPoints": 20,
    "InpMinFVGPoints": 25,
    "InpMinWickRejection": 0.35,
    "InpMinDisplacementPts": 40,
    "InpEMATrendPeriod": 50,
    "InpAsianStartHour": 0,
    "InpAsianEndHour": 7,
    "InpLondonStartHour": 7,
    "InpLondonEndHour": 11,
    "InpNYStartHour": 12,
    "InpNYEndHour": 17,
    "InpEnableVisuals": "false",
    "InpApplyDraculaTheme": "false",
    "InpDrawSetupBoxes": "false"
}

cfg = dict(base_cfg)
cfg['InpStrategyModel'] = 8
cfg['InpMagicNumber'] = 778008

res = run_backtest('m1_model8', '2024.01.01', '2024.01.31', 100.0, cfg)
print(f"Model 8 on M1 (1-Month Trend): Net PnL = ${res['net_profit']:.2f} ({res['roi_pct']:+.1f}%), Trades = {res['total_trades']}, PF = {res['profit_factor']}, DD = {res['drawdown_pct']}%, Status = {res['status']}", flush=True)
