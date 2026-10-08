import os
import shutil
import glob

src_base = r"C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\bases\EGMSecurities-Demo\history"
dst_base = r"d:\MT5_Tester\bases\EGMSecurities-Demo\history"

for sym in ["EURUSD", "XAUUSD"]:
    src_dir = os.path.join(src_base, sym)
    dst_dir = os.path.join(dst_base, sym)
    os.makedirs(dst_dir, exist_ok=True)
    
    for f in os.listdir(src_dir):
        if f == "cache": continue
        src_file = os.path.join(src_dir, f)
        dst_file = os.path.join(dst_dir, f)
        try:
            # Open with read share
            with open(src_file, 'rb') as fin:
                with open(dst_file, 'wb') as fout:
                    shutil.copyfileobj(fin, fout)
            print(f"Copied {sym}\\{f} ({os.path.getsize(dst_file)} bytes)")
        except Exception as e:
            print(f"Could not copy {sym}\\{f}: {e}")

print("Done copying history files!")
