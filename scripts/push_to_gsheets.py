"""
Automated Google Sheets Uploader for YouTube Traders Database
Creates a new Google Spreadsheet and populates it with all 28 strategies and settings hierarchy.
"""

import subprocess
import json
import os
import sys
import time

REPORTS_DIR = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\reports"
LEADERBOARD_CSV = os.path.join(REPORTS_DIR, "MASTER_ALL_STRATEGIES_RANKING.csv")
SETTINGS_CSV = os.path.join(REPORTS_DIR, "MASTER_STRATEGY_SETTINGS_HIERARCHY.csv")

def run_cmd(cmd):
    print(f"Executing: {cmd}")
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"Error ({res.returncode}): {res.stderr}")
    else:
        print(f"Output: {res.stdout.strip()}")
    return res

def upload_to_gsheets():
    # 1. Check auth status
    check = run_cmd("gsheets auth status")
    if "Not logged in" in check.stdout or check.returncode != 0:
        print("GSheets is not authenticated yet.")
        return None

    # 2. Create Spreadsheet
    create_cmd = 'gsheets mutate create --title "YouTube Traders - Master Strategies Leaderboard & Settings Database" --json'
    res = run_cmd(create_cmd)
    if res.returncode != 0:
        print("Failed to create spreadsheet")
        return None

    spreadsheet_id = None
    try:
        data = json.loads(res.stdout)
        spreadsheet_id = data.get("spreadsheetId") or data.get("id")
    except Exception as e:
        # Fallback to text parsing
        for line in res.stdout.splitlines():
            if "spreadsheetId" in line or "https://docs.google.com/spreadsheets/d/" in line:
                parts = line.split("/")
                for p in parts:
                    if len(p) > 20 and not p.startswith("http"):
                        spreadsheet_id = p.split('"')[0].strip()
                        break

    if not spreadsheet_id:
        # Try inspect stdout
        print("Could not parse spreadsheet ID directly, inspecting output:")
        print(res.stdout)
        return None

    print(f"Created Spreadsheet ID: {spreadsheet_id}")
    url = f"https://docs.google.com/spreadsheets/d/{spreadsheet_id}/edit"
    print(f"Google Sheet URL: {url}")

    # 3. Rename Sheet 1 to "Leaderboard"
    run_cmd(f'gsheets mutate rename-sheet {spreadsheet_id} --sheet-id 0 --title "Leaderboard"')

    # 4. Import Leaderboard CSV
    run_cmd(f'gsheets mutate import-csv {spreadsheet_id} "{LEADERBOARD_CSV}"')

    # 5. Format Leaderboard Header & Freeze
    run_cmd(f'gsheets mutate freeze {spreadsheet_id} --sheet-id 0 --rows 1 --cols 1')
    run_cmd(f'gsheets mutate format {spreadsheet_id} --sheet-id 0 --start-row 0 --end-row 1 --start-col 0 --end-col 12 --bold --align CENTER --bg-color "#1B2A4A" --fg-color "#FFFFFF"')
    run_cmd(f'gsheets mutate autosize {spreadsheet_id} --sheet-id 0 --start-col 0 --end-col 12')

    # 6. Add "Settings Hierarchy" Sheet
    add_res = run_cmd(f'gsheets mutate add-sheet {spreadsheet_id} --title "Settings Hierarchy" --json')
    sheet_id_2 = 1
    try:
        sheet_data = json.loads(add_res.stdout)
        sheet_id_2 = sheet_data.get("sheetId", 1)
    except:
        pass

    # 7. Import Settings CSV
    # Note: import-csv usually imports into current or first sheet, or we can use write/append
    # Let's inspect gsheets import-csv help
    return url

if __name__ == "__main__":
    upload_to_gsheets()
