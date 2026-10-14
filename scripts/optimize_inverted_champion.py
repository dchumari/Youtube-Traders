import test_new_windows_baseline as tnwb

print("=== TESTING INVERTED ADAPTIVE RUNNER ENGINE ACROSS BOTH WINDOW SETS ===", flush=True)

# 8 total unique windows
ALL_8_WINDOWS = {
    # Original 4 Random Windows
    "RW1 (Late Jan)": ("2024.01.22", "2024.01.29"),
    "RW2 (Late Apr)": ("2024.04.22", "2024.04.29"),
    "RW3 (Late Aug)": ("2024.08.19", "2024.08.26"),
    "RW4 (Late Oct)": ("2024.10.21", "2024.10.28"),
    # New 4 Unique Windows
    "NW1 (Early Feb)": ("2024.02.05", "2024.02.12"),
    "NW2 (Mid May)": ("2024.05.13", "2024.05.20"),
    "NW3 (Early July)": ("2024.07.08", "2024.07.15"),
    "NW4 (Mid Sept)": ("2024.09.16", "2024.09.23")
}

# Test Model 0, Model 1, Model 5 with ATR filter and Weekly Trailing Shield
for m_id, m_name in [(0, "Trendline Breakout"), (1, "Inducement Breach"), (5, "Quasimodo Head Squeeze")]:
    print(f"\n==================== Inverted Model {m_id}: {m_name} ====================", flush=True)
    tot = 0.0
    p_cnt = 0
    
    for w_name, (w_from, w_to) in ALL_8_WINDOWS.items():
        clean_d = w_from.replace('.', '')
        t_id = f"opt_m{m_id}_{clean_d}"
        
        inputs_dict = {
            "InpCoreModel": m_id,
            "InpHorizonMode": 0,
            "InpMagicNumber": 889400 + m_id,
            "InpEnableDynamicTiering": 1,
            "InpBaseLotSize": 0.02,
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
            "InpMinATRPoints": 110.0, # Volatility filter
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
        else:
            print(f"  {w_name}: No rep", flush=True)
            
    print(f"  >> Model {m_id} Total Net: ${tot:+.2f} | Pass Rate: {p_cnt}/8\n", flush=True)
