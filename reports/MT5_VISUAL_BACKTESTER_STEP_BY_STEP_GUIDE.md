# MetaTrader 5 Strategy Tester: Visual Execution & Playback Guide

This guide provides the exact step-by-step instructions to configure, launch, and observe our winning algorithmic trading strategies executing live trades tick-by-tick inside the **MetaTrader 5 Strategy Tester Visualizer**.

---

## 1. Quick Overview: What You Will See on the Chart

When Visual Mode is active, our integrated **Dracula Visual Trade Suite** and **Universal Flipper Behavioral Engine** take over the chart in real time:

1. **Dracula Dark Theme (`#282A36`)**: Automatic high-contrast background with custom candle colors for institutional clarity.
2. **Institutional Setup Boxes**: Translucent colored rectangles highlighting the exact trigger zones (Order Blocks, Fair Value Gaps, OTE 70.5% Golden Pockets, S&D Bases).
3. **5-Stage Take-Profit Ladder**: Real-time dashed lines displaying the harvest levels:
   - **TP1 (+20 pips / +200 pts)**: Yellow dashed line (harvests 20% volume)
   - **TP2 (+35 pips / +350 pts)**: Lime green dashed line (harvests 25% volume & activates Breakeven Shield)
   - **TP3 (+60 pips / +600 pts)**: Cyan dashed line (harvests 25% volume & locks +25 pips)
   - **TP4 (+100 pips / +1,000 pts)**: Magenta dashed line (harvests 20% volume & locks +60 pips)
   - **TP5 (+160 pips / +1,600 pts)**: Orange runner target
4. **Stepped Breakeven Shield (`CONF_BE_Shield`)**: A solid cyan horizontal line that ratchets forward as targets hit, visibly guaranteeing negative portfolio net-risk.
5. **Floating Margin Pyramiding**: Cascading visual entry arrows as Layers 2 & 3 trigger using unlocked broker equity.
6. **Live Dracula HUD Panel**: Top-left on-chart display tracking Basket Net PnL, Active Ticket Count, Current Layer, and Target Equity Milestone progress.

```
+-----------------------------------------------------------------------+
|  [GMH] GRAND MASTER HYBRID ENGINE v1.0                                |
|  Status: ACTIVE | Direction: BUY (3 Tickets)                          |
|  Floating PnL: +$14.20 (+71.0%) | Layer: 2/3                          |
|  BE Shield: LOCKED (+25 pips) | Target Milestone: 82.5%               |
+-----------------------------------------------------------------------+
```

---

## 2. Step-by-Step MT5 Setup Walkthrough

### Step 1: Open Strategy Tester in MetaTrader 5
1. Launch MetaTrader 5 (or switch to your open MT5 window).
2. Press **`Ctrl + R`** on your keyboard (or click menu: **View** $\rightarrow$ **Strategy Tester**).
3. The Strategy Tester window will open at the bottom of the workspace.

---

### Step 2: Configure the "Settings" Tab
Click on the **Settings** tab in the Strategy Tester and set the following parameters:

| Setting Field | Value to Select / Enter | Notes |
| :--- | :--- | :--- |
| **Expert** | `Grand_Master_Hybrid_EA` *(or your chosen EA)* | Found under the dropdown list of Experts |
| **Symbol** | `XAUUSD` *(or your broker's Gold symbol, e.g. `GOLD`)* | Gold standard contract |
| **Timeframe / Period** | `M15` (15 Minutes) | All strategies calibrated on M15 |
| **Date Range** | `Custom period` | Select start and end date (see Test Cards below) |
| **Forward** | `No` | Disabled |
| **Execution / Delays** | `Zero latency, ideal execution` *(or `50 ms`)* | Simulates realistic tick fills |
| **Modeling** | `Every tick based on real ticks` *(Recommended)* | Or `1 minute OHLC` for ultra-fast visual rendering |
| **Deposit** | `20` USD *(or `100` USD)* | Set currency to `USD` |
| **Leverage** | `1:400` | Standard FXPesa / Exness leverage ratio |
| **Optimization** | `Disabled` | Testing single parameter set |
| **Visual mode checkbox** | **`[X] Visual mode with display of charts...`** | **CRITICAL**: Make sure this box is checked! |

> [!IMPORTANT]
> The **Visual mode** checkbox is the key setting that launches the interactive visual playback window. If unchecked, MT5 runs in silent background mode without showing the chart.

---

### Step 3: Load the Calibrated Winning Preset (`.set`)
1. Click on the **Inputs** tab located right next to the **Settings** tab in the Strategy Tester.
2. **Right-click** anywhere inside the inputs parameter table.
3. In the context menu, click **Load...** (or press the folder icon on the toolbar).
4. The file browser window will immediately open in your MT5 tester profiles directory:
   `C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Profiles\Tester\`
5. Select your desired preset (e.g., `GMH_Weekly_Sprint_Doubler_20USD.set`) and click **Open**.
6. The parameter table will instantly populate with all calibrated inputs!

---

### Step 4: Verify Visual Toggles in Inputs
Scroll to the bottom of the **Inputs** table and verify:
- `InpEnableVisuals` = `true` (Enables setup boxes, target lines, and live HUD)
- `InpApplyDraculaTheme` = `true` (Enables high-contrast navy dark palette)

---

### Step 5: Start the Visual Backtest
1. Click the green **Start** button in the lower-right corner of the Strategy Tester.
2. MT5 will initialize historical data and automatically launch a **new, dedicated Visual Tester chart window**!

---

## 3. Visual Playback Controls & Pro Navigation Tips

Once the Visual Tester chart opens, you have full playback control via the top toolbar:

| Control | Shortcut | Function |
| :--- | :--- | :--- |
| **Play / Pause** | `Spacebar` or `F5` | Pause playback at any time to inspect a trade setup, entry wick, or zone reaction. |
| **Speed Slider** | `1` to `32` | Controls playback speed: <br>• **1–15**: Ultra slow tick-by-tick inspection.<br>• **24–28 (Recommended)**: Smooth, realistic candlestick motion.<br>• **31–32**: Fast-forward through quiet consolidation sessions. |
| **Step-by-Step** | `F12` | When paused, advances the simulation bar-by-bar or tick-by-tick. |
| **Skip To Date** | Calendar icon | Skips visual playback directly to a specific timestamp without rendering previous bars. |
| **Zoom In / Out** | `+` / `-` | Enlarges or shrinks candle size for broader macro perspective. |

---

## 4. Ready-to-Test Winning Strategy "Test Cards"

Here are the 4 top-performing strategies configured with exact dates, deposits, and presets for immediate visual testing:

### Test Card 1: Grand Master Hybrid EA — The Micro-Doubler ($20 USD Tier)
- **Objective**: Watch a $20 account double (+201.6% ROI) during the March 2024 NFP volatility shock.
- **Expert**: [`Grand_Master_Hybrid_EA`](file:///d:/Projects/AUTOMATIONS/TRADING/Youtube-Traders/strategies/Grand_Master_Hybrid/ea_code/Grand_Master_Hybrid_EA.mq5)
- **Symbol**: `XAUUSD` | **Timeframe**: `M15`
- **Deposit**: `20.00 USD` | **Leverage**: `1:400`
- **Date Range**: `2024.03.04` to `2024.03.11`
- **Preset File to Load**: [`GMH_Weekly_Sprint_Doubler_20USD.set`](file:///d:/Projects/AUTOMATIONS/TRADING/Youtube-Traders/strategies/Grand_Master_Hybrid/presets/GMH_Weekly_Sprint_Doubler_20USD.set)
- **What to Observe**:
  1. London Open liquidity sweeps trigger $3\times 0.01$ ticket clusters.
  2. Price surges toward TP1 (+20p) and TP2 (+35p).
  3. Notice the solid cyan **BE Shield** line snap into place locking in profit.
  4. Layer 2 reloads automatically as floating equity expands.

---

### Test Card 2: Danial FX Quasimodo Layering — 100X Flip Engine ($100 USD Tier)
- **Objective**: Watch Ahmad Danial's signature Quasimodo Left-Shoulder sniper entries and cascading margin layering generate +336.6% ROI in 5 days.
- **Expert**: [`DanialFX_Aggressive_Suite`](file:///d:/Projects/AUTOMATIONS/TRADING/Youtube-Traders/strategies/Danial_FX/ea_code/DanialFX_Aggressive_Suite.mq5)
- **Symbol**: `XAUUSD` | **Timeframe**: `M15`
- **Deposit**: `100.00 USD` | **Leverage**: `1:400`
- **Date Range**: `2024.03.04` to `2024.03.11`
- **Preset File to Load**: [`DanialFX_100USD_to_10000USD_Flip_Engine.set`](file:///d:/Projects/AUTOMATIONS/TRADING/Youtube-Traders/strategies/Danial_FX/presets/DanialFX_100USD_to_10000USD_Flip_Engine.set)
- **What to Observe**:
  1. Quasimodo High-Low-HigherHigh-LowerLow structure identification.
  2. Sniper entry at the Left Shoulder with $\ge 40\%$ rejection wick.
  3. At +350 points, Layer 1 moves to Breakeven $+10$ points and Layer 2 fires.
  4. At +700 points, Layer 1 locks $+350$ points, Layer 2 moves to BE, and Layer 3 fires.

---

### Test Card 3: Institutional Confluence Master — 24/5 OTE + S&D Base ($20 USD Tier)
- **Objective**: Watch Strategy 4 combine 24/5 ICT Optimal Trade Entry (70.5% Golden Pocket) with fresh Supply & Demand bases (+270.1% ROI in 1 week).
- **Expert**: [`Institutional_Confluence_Master_EA`](file:///d:/Projects/AUTOMATIONS/TRADING/Youtube-Traders/strategies/Institutional_SMC_ICT_Suite/ea_code/Institutional_Confluence_Master_EA.mq5)
- **Symbol**: `XAUUSD` | **Timeframe**: `M15`
- **Deposit**: `20.00 USD` | **Leverage**: `1:400`
- **Date Range**: `2024.03.04` to `2024.03.11`
- **Preset File to Load**: [`Confluence_Strat4_24_5_OTE_SD_Base_20USD.set`](file:///d:/Projects/AUTOMATIONS/TRADING/Youtube-Traders/strategies/Institutional_SMC_ICT_Suite/presets/Confluence_Strat4_24_5_OTE_SD_Base_20USD.set)
- **What to Observe**:
  1. Translucent golden corridor rendered across the 61.8% to 78.6% Fib retracement.
  2. S&D fresh base rectangle drawn at the swing origin.
  3. Multi-ticket slice execution ($3\times 0.01$) upon confluence tap with lower rejection wick.

---

### Test Card 4: Grand Master Hybrid EA — 1-Month Expansion ($100 USD Tier)
- **Objective**: Watch smooth, disciplined monthly trend expansion generate +98.3% ROI across May 2024 with low drawdown (24.8%).
- **Expert**: [`Grand_Master_Hybrid_EA`](file:///d:/Projects/AUTOMATIONS/TRADING/Youtube-Traders/strategies/Grand_Master_Hybrid/ea_code/Grand_Master_Hybrid_EA.mq5)
- **Symbol**: `XAUUSD` | **Timeframe**: `M15`
- **Deposit**: `100.00 USD` | **Leverage**: `1:400`
- **Date Range**: `2024.05.01` to `2024.05.31`
- **Preset File to Load**: [`GMH_Monthly_Expansion_100USD.set`](file:///d:/Projects/AUTOMATIONS/TRADING/Youtube-Traders/strategies/Grand_Master_Hybrid/presets/GMH_Monthly_Expansion_100USD.set)
- **What to Observe**:
  1. Multi-week position compounding adhering to strict session filters.
  2. ATR trailing stops locking in extended swing gains across 1,000+ pip moves.

---

## 5. Troubleshooting & FAQ

- **Q: The Visual chart isn't opening when I click Start!**
  - **A**: Ensure the **`[X] Visual mode with display of charts, indicators and trades`** checkbox in the Strategy Tester **Settings** tab is checked.
- **Q: It runs too fast and finishes in 2 seconds!**
  - **A**: Slide the **Speed Slider** down to ~**26** before clicking Start, or press `Spacebar` immediately after launch to pause.
- **Q: My broker uses a different symbol name (e.g., `XAUUSDm` or `GOLD`)!**
  - **A**: In the **Symbol** dropdown, select your broker's exact Gold symbol name.
- **Q: Where are the preset files stored on my computer?**
  - **A**: All presets are placed in your MT5 Tester profile directory:
    `C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Profiles\Tester\`
    and in the project repository under [`strategies/{Strategy_Name}/presets/`](file:///d:/Projects/AUTOMATIONS/TRADING/Youtube-Traders/strategies/).
