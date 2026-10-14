import test_new_windows_baseline as tnwb

models = {
    "Model 0 (Trendline Trap Breakout)": 0,
    "Model 1 (Inducement / OB Breach)": 1,
    "Model 5 (Quasimodo Head Squeeze)": 5,
    "Model 7 (Matteo Bank ORB)": 7,
    "Model 8 (Master Trap Confluence)": 8,
    "Model 9 (Hybrid QM + Bank ORB)": 9
}

print("=== SCREENING ALL INVERTED MODELS ACROSS 4 NEW UNIQUE 2024 WINDOWS ($100 DEPOSIT) ===", flush=True)

results = {}

for m_label, m_id in models.items():
    print(f"\n=================== {m_label} ===================", flush=True)
    tot = 0.0
    p_cnt = 0
    w_res = {}
    
    for w_name, (w_from, w_to) in tnwb.NEW_UNIQUE_WINDOWS.items():
        clean_d = w_from.replace('.', '')
        t_id = f"scr_m{m_id}_{clean_d}"
        
        inputs_dict = {
            "InpCoreModel": m_id,
            "InpHorizonMode": 0,
            "InpMagicNumber": 889300 + m_id,
            "InpEnableDynamicTiering": 1,
            "InpBaseLotSize": 0.01,
            "InpEquityTierStep": 50.0,
            "InpMaxLotCap": 0.20,
            "InpBaseStopLossPoints": 150,
            "InpSpamTicketsCount": 2, # Using 2 tickets for margin safety
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
        
        res = tnwb.run_test(t_id, "XAUUSD", "SMC_Inverted_Momentum_EA", w_from, w_to, 100.0, inputs_dict)
        if res:
            p = res["profit"]
            tot += p
            if p > 0: p_cnt += 1
            status = "WIN" if p > 0 else "LOSS"
            print(f"  {w_name}: Net=${p:+.2f} | Trades={res['trades']} | WR={res['win_pct']:.1f}% | PF={res['pf']:.2f} | DD=${res['dd']:.2f} | {status}", flush=True)
            w_res[w_name] = res
        else:
            print(f"  {w_name}: No rep", flush=True)
            w_res[w_name] = None
            
    print(f"  >> {m_label} CUMULATIVE: Net=${tot:+.2f} | PASS RATE: {p_cnt}/4", flush=True)
    results[m_label] = {"tot": tot, "pass": p_cnt}

print("\n\n=================== SUMMARY LEADERBOARD ON NEW WINDOWS ===================", flush=True)
for k, v in sorted(results.items(), key=lambda x: x[1]["tot"], reverse=True):
    print(f"{k:45} | Net Profit: ${v['tot']:+7.2f} | Passed: {v['pass']}/4", flush=True)
