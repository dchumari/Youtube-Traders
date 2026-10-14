import test_new_windows_baseline as tnwb

print("=== TESTING MODEL 1 (INDUCEMENT BREACH + EMA FILTER) ACROSS 4 NEW UNIQUE WINDOWS ($100 DEPOSIT) ===", flush=True)

inputs_dict = {
    "InpCoreModel": 1,
    "InpHorizonMode": 0,
    "InpMagicNumber": 889301,
    "InpEnableDynamicTiering": 1,
    "InpBaseLotSize": 0.02, # 0.02 per ticket x 2 tickets = 0.04 lots
    "InpEquityTierStep": 50.0,
    "InpMaxLotCap": 0.20,
    "InpBaseStopLossPoints": 150,
    "InpSpamTicketsCount": 2,
    "InpTP1Points": 150,
    "InpTP2Points": 450,
    "InpTP3Points": 800,
    "InpTP4Points": 1200,
    "InpTP5Points": 1800,
    "InpEnablePyramiding": 0,
    "InpEnableDumpAndFlip": 0,
    "InpRequireDisplacement": 1,
    "InpMinDisplacementPct": 0.40,
    "InpSwingLookback": 28,
    "InpTrendlinePoints": 3,
    "InpMinSweepPoints": 100,
    "InpMinWickRejection": 0.35,
    "InpEMATrendPeriod": 50,
    "InpVolumeSurgeMult": 1.5,
    "InpMinATRPoints": 100.0,
    "InpUseSessionFilter": 1,
    "InpLondonStartHour": 7,
    "InpLondonEndHour": 11,
    "InpNYStartHour": 12,
    "InpNYEndHour": 18,
    "InpGMTOffset": 3,
    "InpMaxDailyTrades": 2,
    "InpMinTradeCooldownMin": 90,
    "InpEnableDailyDoubleLockout": 1,
    "InpDailyTargetPct": 100.0,
    "InpEnableWeeklyTargetLockout": 0,
    "InpWeeklyTargetPct": 100.0,
    "InpEnableWeeklyTrailingShield": 1,
    "InpWeeklyMaxGivebackPct": 35.0,
    "InpMaxHoldingBars": 8,
    "InpEnableStructuralExit": 1,
    "InpEnableVisuals": 0,
    "InpApplyDraculaTheme": 0
}

tot = 0.0
p_cnt = 0
for w_name, (w_from, w_to) in tnwb.NEW_UNIQUE_WINDOWS.items():
    clean_d = w_from.replace('.', '')
    t_id = f"inv_m1_cal_{clean_d}"
    res = tnwb.run_test(t_id, "XAUUSD", "SMC_Inverted_Momentum_EA", w_from, w_to, 100.0, inputs_dict)
    if res:
        p = res["profit"]
        tot += p
        if p > 0: p_cnt += 1
        status = "WIN" if p > 0 else "LOSS"
        print(f"  {w_name}: Net=${p:+.2f} | Trades={res['trades']} | WR={res['win_pct']:.1f}% | PF={res['pf']:.2f} | DD=${res['dd']:.2f} | {status}", flush=True)
    else:
        print(f"  {w_name}: No rep", flush=True)

print(f"  >> UPDATED INVERTED MODEL 1 CUMULATIVE: Net=${tot:+.2f} | PASS RATE: {p_cnt}/4\n", flush=True)
