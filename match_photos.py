import json
import os
from datetime import datetime
import csv

data = json.loads('''[{"seat_no":"5402150002","student_name":"THORAT ALOK KAPIL","entry_photo_at":"2026-07-04 10:15:43.397961"},{"seat_no":"5402150005","student_name":"BHALERAO AMARDEEP GANPATI","entry_photo_at":"2026-07-04 10:22:29.689183"},{"seat_no":"5402150018","student_name":"RAUT ANANTA BALASAHEB","entry_photo_at":"2026-07-04 10:42:03.383768"},{"seat_no":"5402150019","student_name":"SHIVLAD ANGHALAXMI GANESH","entry_photo_at":"2026-07-04 10:10:38.500219"},{"seat_no":"5402150024","student_name":"NAVEKAR ANIRUDDHA ABHIJEET","entry_photo_at":"2026-07-04 11:12:18.853009"},{"seat_no":"5402150028","student_name":"SHAIKH ANJUM FARUKH","entry_photo_at":"2026-07-04 10:19:18.651091"},{"seat_no":"5402150029","student_name":"SABLE ANKITA ANIL","entry_photo_at":"2026-07-04 10:09:40.078817"},{"seat_no":"5402150032","student_name":"ASHARIB ANSARI ANSARI ABDUL SAYEED","entry_photo_at":"2026-07-04 10:24:06.258396"},{"seat_no":"5402150033","student_name":"DOMBE ANUJA BHAGWAN","entry_photo_at":"2026-07-04 10:11:27.0033"},{"seat_no":"5402150036","student_name":"CHORGE ANUSHKA ANIL","entry_photo_at":"2026-07-04 10:26:19.784835"},{"seat_no":"5402150037","student_name":"GHUGE ANUSHKA SUNIL","entry_photo_at":"2026-07-04 10:33:14.283794"},{"seat_no":"5402150041","student_name":"ZINJE ARCHANA BHARAT","entry_photo_at":"2026-07-04 10:30:17.710258"},{"seat_no":"5402150047","student_name":"MADKE ASHATAI SANGRAM","entry_photo_at":"2026-07-04 10:27:08.840636"},{"seat_no":"5402150048","student_name":"SONUNE ASHISH SANTOSH","entry_photo_at":"2026-07-04 10:08:25.94466"},{"seat_no":"5402150053","student_name":"HANDIBAG ASHWINI DNYANOBA","entry_photo_at":"2026-07-04 10:21:12.761048"},{"seat_no":"5402150054","student_name":"HUMBE ASHWINI NAVNATH","entry_photo_at":"2026-07-04 10:27:31.89219"},{"seat_no":"5402150056","student_name":"SANAS ASHWINI VISHNU","entry_photo_at":"2026-07-04 10:40:32.977761"},{"seat_no":"5402150057","student_name":"AMBHORE ASMITA BHARAT","entry_photo_at":"2026-07-04 10:18:08.938514"},{"seat_no":"5402150059","student_name":"THALKARI ATHARV SHAMAPPA","entry_photo_at":"2026-07-04 10:12:35.272429"}]''')

base_folder = "/Users/bhushan/Downloads/4ef573e8-d1e3-4f7a-b467-641b5e9652f9 3/2026/001"

# Get all files with timestamps
files_list = []
for root, dirs, files in os.walk(base_folder):
    for f in files:
        if f.endswith('.jpg'):
            path = os.path.join(root, f)
            mtime = os.path.getmtime(path)
            mtime_dt = datetime.fromtimestamp(mtime)
            files_list.append((path, mtime, mtime_dt))

files_list.sort(key=lambda x: x[1])

print(f"Found {len(files_list)} files\n")
print("MATCHING TABLE:")
print("=" * 120)
print(f"{'Seat No':<15} {'Student Name':<40} {'DB Timestamp':<25} {'File Timestamp':<25} {'Diff (sec)':<12} {'Status':<10}")
print("=" * 120)

matched = []
for student in data:
    db_time_str = student['entry_photo_at'].split('.')[0]
    db_time = datetime.strptime(db_time_str, "%Y-%m-%d %H:%M:%S")
    db_timestamp = db_time.timestamp()

    # Find file within +5 seconds
    best_match = None
    best_diff = float('inf')

    for fpath, mtime, mtime_dt in files_list:
        diff = mtime - db_timestamp

        # Only plus direction: 0 to +5 seconds
        if 0 <= diff <= 5 and diff < best_diff:
            best_match = (fpath, mtime_dt, diff)
            best_diff = diff

    if best_match:
        fpath, mtime_dt, diff = best_match
        print(f"{student['seat_no']:<15} {student['student_name'][:40]:<40} {str(db_time):<25} {str(mtime_dt):<25} {diff:<12.2f} {'✓ MATCH':<10}")
        matched.append({
            'seat_no': student['seat_no'],
            'student_name': student['student_name'],
            'file_path': fpath,
            'db_time': str(db_time),
            'file_time': str(mtime_dt),
            'diff': diff
        })
    else:
        print(f"{student['seat_no']:<15} {student['student_name'][:40]:<40} {str(db_time):<25} {'N/A':<25} {'N/A':<12} {'✗ NO MATCH':<10}")

print("=" * 120)
print(f"\n✅ Matched: {len(matched)} / {len(data)}")

# Save to CSV
csv_path = "/Users/bhushan/Desktop/PROJECTS/maha-maintanpro-main/photo_matches.csv"
with open(csv_path, 'w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=['seat_no', 'student_name', 'file_path', 'db_time', 'file_time', 'diff'])
    writer.writeheader()
    writer.writerows(matched)

print(f"\n📊 Results saved to: {csv_path}")
