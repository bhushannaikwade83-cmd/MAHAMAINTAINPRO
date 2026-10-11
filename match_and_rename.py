import os
from datetime import datetime
import json

# Database with timestamps
data = json.loads('''[{"seat_no":"5402150002","student_name":"THORAT ALOK KAPIL","entry_photo_at":"2026-07-04 10:15:43"},{"seat_no":"5402150005","student_name":"BHALERAO AMARDEEP GANPATI","entry_photo_at":"2026-07-04 10:22:29"},{"seat_no":"5402150018","student_name":"RAUT ANANTA BALASAHEB","entry_photo_at":"2026-07-04 10:42:03"},{"seat_no":"5402150019","student_name":"SHIVLAD ANGHALAXMI GANESH","entry_photo_at":"2026-07-04 10:10:38"},{"seat_no":"5402150024","student_name":"NAVEKAR ANIRUDDHA ABHIJEET","entry_photo_at":"2026-07-04 11:12:18"},{"seat_no":"5402150028","student_name":"SHAIKH ANJUM FARUKH","entry_photo_at":"2026-07-04 10:19:18"},{"seat_no":"5402150029","student_name":"SABLE ANKITA ANIL","entry_photo_at":"2026-07-04 10:09:40"},{"seat_no":"5402150032","student_name":"ASHARIB ANSARI ANSARI ABDUL SAYEED","entry_photo_at":"2026-07-04 10:24:06"},{"seat_no":"5402150033","student_name":"DOMBE ANUJA BHAGWAN","entry_photo_at":"2026-07-04 10:11:27"},{"seat_no":"5402150036","student_name":"CHORGE ANUSHKA ANIL","entry_photo_at":"2026-07-04 10:26:19"},{"seat_no":"5402150037","student_name":"GHUGE ANUSHKA SUNIL","entry_photo_at":"2026-07-04 10:33:14"},{"seat_no":"5402150041","student_name":"ZINJE ARCHANA BHARAT","entry_photo_at":"2026-07-04 10:30:17"},{"seat_no":"5402150047","student_name":"MADKE ASHATAI SANGRAM","entry_photo_at":"2026-07-04 10:27:08"},{"seat_no":"5402150048","student_name":"SONUNE ASHISH SANTOSH","entry_photo_at":"2026-07-04 10:08:25"},{"seat_no":"5402150053","student_name":"HANDIBAG ASHWINI DNYANOBA","entry_photo_at":"2026-07-04 10:21:12"},{"seat_no":"5402150054","student_name":"HUMBE ASHWINI NAVNATH","entry_photo_at":"2026-07-04 10:27:31"},{"seat_no":"5402150056","student_name":"SANAS ASHWINI VISHNU","entry_photo_at":"2026-07-04 10:40:32"},{"seat_no":"5402150057","student_name":"AMBHORE ASMITA BHARAT","entry_photo_at":"2026-07-04 10:18:08"},{"seat_no":"5402150059","student_name":"THALKARI ATHARV SHAMAPPA","entry_photo_at":"2026-07-04 10:12:35"}]''')

folder = "/Users/bhushan/Downloads/4ef573e8-d1e3-4f7a-b467-641b5e9652f9 3/2026/001/english_30/2026-07-04"

# Get all files with timestamps
files_list = []
for f in os.listdir(folder):
    if f.endswith('.jpg'):
        path = os.path.join(folder, f)
        mtime = os.path.getmtime(path)
        mtime_dt = datetime.fromtimestamp(mtime)
        files_list.append((f, path, mtime, mtime_dt))

files_list.sort(key=lambda x: x[2])

print("MATCHING & RENAMING TABLE:")
print("=" * 130)
print(f"{'File':<20} {'File Time':<20} {'Seat No':<15} {'Student Name':<40} {'DB Time':<20} {'Diff':<10} {'Action':<15}")
print("=" * 130)

matched_count = 0
for file, path, mtime, mtime_dt in files_list:
    best_match = None
    best_diff = float('inf')

    for student in data:
        db_time_str = student['entry_photo_at']
        db_time = datetime.strptime(db_time_str, "%Y-%m-%d %H:%M:%S")
        db_timestamp = db_time.timestamp()

        diff = db_timestamp - mtime

        # File is up to 5 seconds BEFORE database time
        if 0 <= diff <= 5 and diff < best_diff:
            best_match = student
            best_diff = diff

    if best_match:
        seat_no = best_match['seat_no']
        new_name = f"{seat_no}_entry.jpg"
        new_path = os.path.join(folder, new_name)

        try:
            os.rename(path, new_path)
            action = "✓ RENAMED"
            matched_count += 1
        except:
            action = "✗ ERROR"

        print(f"{file:<20} {str(mtime_dt):<20} {seat_no:<15} {best_match['student_name'][:40]:<40} {best_match['entry_photo_at']:<20} {best_diff:<10.2f} {action:<15}")
    else:
        print(f"{file:<20} {str(mtime_dt):<20} {'N/A':<15} {'No match':<40} {'N/A':<20} {'N/A':<10} {'SKIP':<15}")

print("=" * 130)
print(f"\n✅ Renamed: {matched_count} / {len(files_list)}")
