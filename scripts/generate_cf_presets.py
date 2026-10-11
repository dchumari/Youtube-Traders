import os

PRESET_DIR = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\strategies\Chart_Fanatics\presets"
os.makedirs(PRESET_DIR, exist_ok=True)

presets = {
    # 1. Matteo Conti ORB - Original Trader
    "CF_MatteoConti_ORB_Original.set": """InpStrategyModel=0
InpSettingsMode=0
InpMagicNumber=888100
InpFixedLot=0.01
InpEquityPerMinLot=25.0
InpMaxLotCap=2.00
InpTicketSlices=1
InpEnablePyramiding=false
InpMaxPyramidLayers=1
InpPyramidSpacingPts=350
InpORB_Minutes=15
InpORB_StartHour=8
InpORB_StartMinute=0
InpORB_TPMultiplier=1.5
InpORB_UseMidlineSL=false
InpUseSteppedBE=false
InpBE_TriggerPoints=250
InpBE_LockPoints=10
InpUseTrailingATR=false
""",

    # 2. Matteo Conti ORB - Calibrated Optimal
    "CF_MatteoConti_ORB_Optimal.set": """InpStrategyModel=0
InpSettingsMode=1
InpMagicNumber=888100
InpFixedLot=0.01
InpEquityPerMinLot=25.0
InpMaxLotCap=2.00
InpTicketSlices=5
InpEnablePyramiding=true
InpMaxPyramidLayers=3
InpPyramidSpacingPts=300
InpORB_Minutes=30
InpORB_StartHour=8
InpORB_StartMinute=0
InpORB_TPMultiplier=2.5
InpORB_UseMidlineSL=true
InpUseSteppedBE=true
InpBE_TriggerPoints=250
InpBE_LockPoints=10
InpUseTrailingATR=true
InpTrailingATRPeriod=14
InpTrailingATRMult=1.5
""",

    # 3. Trader Yush Value Area - Original Trader
    "CF_TraderYush_ValueArea_Original.set": """InpStrategyModel=2
InpSettingsMode=0
InpMagicNumber=888102
InpFixedLot=0.01
InpEquityPerMinLot=25.0
InpMaxLotCap=2.00
InpTicketSlices=1
InpEnablePyramiding=false
InpMaxPyramidLayers=1
InpPyramidSpacingPts=350
InpVA_LookbackBars=48
InpVA_Percentage=70.0
InpAbsorptionVolMult=2.0
InpRejectionWickMin=0.35
InpUseSteppedBE=false
InpBE_TriggerPoints=250
InpBE_LockPoints=10
InpUseTrailingATR=false
""",

    # 4. Trader Yush Value Area - Calibrated Optimal
    "CF_TraderYush_ValueArea_Optimal.set": """InpStrategyModel=2
InpSettingsMode=1
InpMagicNumber=888102
InpFixedLot=0.01
InpEquityPerMinLot=25.0
InpMaxLotCap=2.00
InpTicketSlices=5
InpEnablePyramiding=true
InpMaxPyramidLayers=3
InpPyramidSpacingPts=300
InpVA_LookbackBars=48
InpVA_Percentage=70.0
InpAbsorptionVolMult=2.2
InpRejectionWickMin=0.40
InpUseSteppedBE=true
InpBE_TriggerPoints=200
InpBE_LockPoints=10
InpUseTrailingATR=true
InpTrailingATRPeriod=14
InpTrailingATRMult=1.5
""",

    # 5. Okala 80/20 Distribution - Original Trader
    "CF_Okala_8020_Original.set": """InpStrategyModel=3
InpSettingsMode=0
InpMagicNumber=888103
InpFixedLot=0.01
InpEquityPerMinLot=25.0
InpMaxLotCap=2.00
InpTicketSlices=1
InpEnablePyramiding=false
InpMaxPyramidLayers=1
InpPyramidSpacingPts=350
InpOkalaRangeBars=96
InpOkalaTailPct=20.0
InpOkalaStopPts=200
InpOkalaTP_Pts=400
InpUseSteppedBE=false
InpBE_TriggerPoints=250
InpBE_LockPoints=10
InpUseTrailingATR=false
""",

    # 6. Okala 80/20 Distribution - Calibrated Optimal
    "CF_Okala_8020_Optimal.set": """InpStrategyModel=3
InpSettingsMode=1
InpMagicNumber=888103
InpFixedLot=0.01
InpEquityPerMinLot=25.0
InpMaxLotCap=2.00
InpTicketSlices=5
InpEnablePyramiding=true
InpMaxPyramidLayers=3
InpPyramidSpacingPts=300
InpOkalaRangeBars=96
InpOkalaTailPct=20.0
InpOkalaStopPts=180
InpOkalaTP_Pts=550
InpUseSteppedBE=true
InpBE_TriggerPoints=200
InpBE_LockPoints=10
InpUseTrailingATR=true
InpTrailingATRPeriod=14
InpTrailingATRMult=1.5
""",

    # 7. Anthony Crudele Bollinger Trend - Calibrated Optimal
    "CF_Crudele_Bollinger_Optimal.set": """InpStrategyModel=4
InpSettingsMode=1
InpMagicNumber=888104
InpFixedLot=0.01
InpEquityPerMinLot=25.0
InpMaxLotCap=2.00
InpTicketSlices=5
InpEnablePyramiding=true
InpMaxPyramidLayers=3
InpPyramidSpacingPts=300
InpBB_Period=20
InpBB_Deviation=2.0
InpBB_TrendEMA=50
InpBB_StopPts=220
InpBB_TargetPts=550
InpUseSteppedBE=true
InpBE_TriggerPoints=220
InpBE_LockPoints=10
InpUseTrailingATR=true
InpTrailingATRPeriod=14
InpTrailingATRMult=1.5
""",

    # 8. Kris Verma Parabolic Gap Short - Calibrated Optimal
    "CF_KrisVerma_GapShort_Optimal.set": """InpStrategyModel=5
InpSettingsMode=1
InpMagicNumber=888105
InpFixedLot=0.01
InpEquityPerMinLot=25.0
InpMaxLotCap=2.00
InpTicketSlices=5
InpEnablePyramiding=true
InpMaxPyramidLayers=3
InpPyramidSpacingPts=300
InpGapMinPoints=250
InpVermaWickMin=0.40
InpVermaStopPts=200
InpVermaTP_Pts=600
InpUseSteppedBE=true
InpBE_TriggerPoints=250
InpBE_LockPoints=10
InpUseTrailingATR=true
InpTrailingATRPeriod=14
InpTrailingATRMult=1.5
""",

    # 9. Chart Fanatics Master Hybrid Confluence - Calibrated Optimal
    "CF_Master_Hybrid_Optimal.set": """InpStrategyModel=6
InpSettingsMode=1
InpMagicNumber=888106
InpFixedLot=0.01
InpEquityPerMinLot=25.0
InpMaxLotCap=2.00
InpTicketSlices=5
InpEnablePyramiding=true
InpMaxPyramidLayers=4
InpPyramidSpacingPts=300
InpORB_Minutes=30
InpORB_StartHour=8
InpORB_StartMinute=0
InpORB_TPMultiplier=2.5
InpORB_UseMidlineSL=true
InpVA_LookbackBars=48
InpVA_Percentage=70.0
InpAbsorptionVolMult=2.0
InpRejectionWickMin=0.35
InpUseSteppedBE=true
InpBE_TriggerPoints=200
InpBE_LockPoints=10
InpUseTrailingATR=true
InpTrailingATRPeriod=14
InpTrailingATRMult=1.5
"""
}

for name, content in presets.items():
    path = os.path.join(PRESET_DIR, name)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content.strip() + "\n")
    print(f"Generated preset: {name}")

print(f"\nSuccessfully generated all {len(presets)} presets in {PRESET_DIR}")
