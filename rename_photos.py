import json
import os
from datetime import datetime

data = json.loads('''[{"idx":0,"seat_no":"5402150002","student_name":"THORAT ALOK KAPIL","entry_photo_at":"2026-07-04 10:15:43.397961"},{"idx":1,"seat_no":"5402150005","student_name":"BHALERAO AMARDEEP GANPATI","entry_photo_at":"2026-07-04 10:22:29.689183"},{"idx":2,"seat_no":"5402150018","student_name":"RAUT ANANTA BALASAHEB","entry_photo_at":"2026-07-04 10:42:03.383768"},{"idx":3,"seat_no":"5402150019","student_name":"SHIVLAD ANGHALAXMI GANESH","entry_photo_at":"2026-07-04 10:10:38.500219"},{"idx":4,"seat_no":"5402150024","student_name":"NAVEKAR ANIRUDDHA ABHIJEET","entry_photo_at":"2026-07-04 11:12:18.853009"},{"idx":5,"seat_no":"5402150028","student_name":"SHAIKH ANJUM FARUKH","entry_photo_at":"2026-07-04 10:19:18.651091"},{"idx":6,"seat_no":"5402150029","student_name":"SABLE ANKITA ANIL","entry_photo_at":"2026-07-04 10:09:40.078817"},{"idx":7,"seat_no":"5402150032","student_name":"ASHARIB ANSARI ANSARI ABDUL SAYEED","entry_photo_at":"2026-07-04 10:24:06.258396"},{"idx":8,"seat_no":"5402150033","student_name":"DOMBE ANUJA BHAGWAN","entry_photo_at":"2026-07-04 10:11:27.0033"}]''')

base_folder = "./4ef573e8-d1e3-4f7a-b467-641b5e9652f9/2026/001"

# Get all files with timestamps
files_dict = {}
for root, dirs, files in os.walk(base_folder):
    for f in files:
        if f.endswith('.jpg'):
            path = os.path.join(root, f)
            mtime = os.path.getmtime(path)
            files_dict[mtime] = path

print(f"Found {len(files_dict)} files")
print(f"Found {len(data)} students in database\n")

# Match + Rename
renamed_count = 0
failed = 0

for student in data:
    db_time_str = student['entry_photo_at'].split('.')[0]
    db_time = datetime.strptime(db_time_str, "%Y-%m-%d %H:%M:%S")
    db_timestamp = db_time.timestamp()

    # Find closest file (within 10 seconds)
    closest_file = None
    closest_diff = float('inf')

    for mtime, fpath in files_dict.items():
        diff = abs(mtime - db_timestamp)
        if diff < 10 and diff < closest_diff:
            closest_file = fpath
            closest_diff = diff

    if closest_file:
        folder = os.path.dirname(closest_file)
        new_name = f"{student['seat_no']}_entry.jpg"
        new_path = os.path.join(folder, new_name)
        try:
            os.rename(closest_file, new_path)
            print(f"✓ {student['seat_no']} - {student['student_name'][:40]}")
            renamed_count += 1
        except Exception as e:
            print(f"✗ {student['seat_no']} - Error: {e}")
            failed += 1
    else:
        print(f"✗ {student['seat_no']} - No matching file (diff: {closest_diff:.1f}s)")
        failed += 1

print(f"\n✅ Renamed: {renamed_count}")
print(f"❌ Failed: {failed}")
