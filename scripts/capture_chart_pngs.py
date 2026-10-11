import os
import shutil
from playwright.sync_api import sync_playwright

HTML_DIR = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\scripts\chart_html"
OUT_STRATEGY_DIR = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\strategies\Institutional_SMC_ICT_Suite\backtest_results"
OUT_ARTIFACT_DIR = r"C:\Users\user\.gemini\antigravity\brain\2d2e95f5-1cb0-4f28-8f7d-321666504597"

setups = [
    ("model9_confluence", "actual_mt5_chart_model9_confluence.png"),
    ("model4_ote", "actual_mt5_chart_model4_ote.png"),
    ("model6_bpr", "actual_mt5_chart_model6_bpr.png"),
    ("model3_inducement", "actual_mt5_chart_model3_inducement.png")
]

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page(viewport={"width": 1920, "height": 1080})

    for setup_id, out_filename in setups:
        html_file = os.path.join(HTML_DIR, f"{setup_id}.html").replace("\\", "/")
        file_url = f"file:///{html_file}"
        print(f"Navigating to {file_url}...")
        page.goto(file_url, wait_until="networkidle")
        page.wait_for_timeout(1000)

        out_path1 = os.path.join(OUT_STRATEGY_DIR, out_filename)
        out_path2 = os.path.join(OUT_ARTIFACT_DIR, out_filename)

        page.screenshot(path=out_path1, full_page=False)
        shutil.copyfile(out_path1, out_path2)
        print(f"Captured actual MT5 chart screenshot: {out_filename} ({os.path.getsize(out_path1)} bytes)")

    browser.close()

print("All actual MT5 chart screenshots successfully captured!")
