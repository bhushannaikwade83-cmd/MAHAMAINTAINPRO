import os
import shutil
from datetime import datetime

# Batch schedule
batches = [
    {"date": "2026-07-04", "batch": "101", "start": "09:00", "end": "10:30"},
    {"date": "2026-07-04", "batch": "102", "start": "11:15", "end": "12:45"},
    {"date": "2026-07-04", "batch": "103", "start": "13:30", "end": "15:00"},
    {"date": "2026-07-04", "batch": "104", "start": "15:45", "end": "17:15"},
    {"date": "2026-07-06", "batch": "201", "start": "09:00", "end": "10:30"},
    {"date": "2026-07-06", "batch": "202", "start": "11:15", "end": "12:45"},
    {"date": "2026-07-06", "batch": "203", "start": "13:30", "end": "15:00"},
    {"date": "2026-07-06", "batch": "204", "start": "15:45", "end": "17:15"},
    {"date": "2026-07-07", "batch": "301", "start": "09:00", "end": "10:30"},
    {"date": "2026-07-07", "batch": "302", "start": "11:15", "end": "12:45"},
    {"date": "2026-07-07", "batch": "303", "start": "13:30", "end": "15:00"},
    {"date": "2026-07-07", "batch": "304", "start": "15:45", "end": "17:15"},
    {"date": "2026-07-08", "batch": "401", "start": "09:00", "end": "10:30"},
    {"date": "2026-07-08", "batch": "402", "start": "11:15", "end": "12:45"},
    {"date": "2026-07-08", "batch": "403", "start": "13:30", "end": "15:00"},
    {"date": "2026-07-08", "batch": "404", "start": "15:45", "end": "17:15"},
    {"date": "2026-07-09", "batch": "501", "start": "09:00", "end": "10:30"},
    {"date": "2026-07-09", "batch": "502", "start": "11:15", "end": "12:45"},
    {"date": "2026-07-09", "batch": "503", "start": "13:30", "end": "15:00"},
    {"date": "2026-07-09", "batch": "504", "start": "15:45", "end": "17:15"},
    {"date": "2026-07-10", "batch": "601", "start": "09:00", "end": "10:30"},
    {"date": "2026-07-10", "batch": "602", "start": "11:15", "end": "12:45"},
    {"date": "2026-07-10", "batch": "603", "start": "13:30", "end": "15:00"},
    {"date": "2026-07-15", "batch": "1101", "start": "09:00", "end": "10:30"},
    {"date": "2026-07-15", "batch": "1102", "start": "11:15", "end": "12:45"},
    {"date": "2026-07-15", "batch": "1103", "start": "13:30", "end": "15:00"},
    {"date": "2026-07-15", "batch": "1104", "start": "15:45", "end": "17:15"},
    {"date": "2026-07-16", "batch": "1201", "start": "09:00", "end": "10:30"},
    {"date": "2026-07-16", "batch": "1202", "start": "11:15", "end": "12:45"},
    {"date": "2026-07-16", "batch": "1203", "start": "13:30", "end": "15:00"},
    {"date": "2026-07-16", "batch": "1204", "start": "15:45", "end": "17:15"},
    {"date": "2026-07-17", "batch": "1301", "start": "09:00", "end": "10:30"},
    {"date": "2026-07-17", "batch": "1302", "start": "11:15", "end": "12:45"},
    {"date": "2026-07-17", "batch": "1303", "start": "13:30", "end": "15:00"},
    {"date": "2026-07-17", "batch": "1304", "start": "15:45", "end": "17:15"},
    {"date": "2026-07-18", "batch": "1401", "start": "09:00", "end": "10:30"},
]

base_folder = "/Users/bhushan/Downloads/dde2a01c-4ab7-4fdc-ab3d-2fd7819b05ef/2026/001"
output_base = "/Users/bhushan/Downloads/dde2a01c-4ab7-4fdc-ab3d-2fd7819b05ef/2026_Organized"

# Get all entry files
files_list = []
for root, dirs, files in os.walk(base_folder):
    for f in files:
        if f.startswith('entry_') and f.endswith('.jpg'):
            path = os.path.join(root, f)
            files_list.append((f, path))

print(f"Found {len(files_list)} entry files\n")
print("ORGANIZING FILES BY BATCH:")
print("=" * 100)
print(f"{'File':<30} {'File Date/Time':<20} {'Batch':<10} {'Folder':<50} {'Status':<10}")
print("=" * 100)

moved_count = 0
for file, path in sorted(files_list):
    # Extract date and time from filename: entry_YYYYMMDD_HHMMSS.jpg
    try:
        parts = file.replace('entry_', '').replace('.jpg', '').split('_')
        file_date = parts[0]  # YYYYMMDD
        file_time = parts[1]  # HHMMSS

        file_date_fmt = f"{file_date[:4]}-{file_date[4:6]}-{file_date[6:8]}"
        file_hour = int(file_time[:2])
        file_min = int(file_time[2:4])

        # Find matching batch
        best_batch = None
        for batch in batches:
            if batch['date'] == file_date_fmt:
                start_h, start_m = map(int, batch['start'].split(':'))
                end_h, end_m = map(int, batch['end'].split(':'))

                start_mins = start_h * 60 + start_m
                end_mins = end_h * 60 + end_m
                file_mins = file_hour * 60 + file_min

                if start_mins <= file_mins <= end_mins:
                    best_batch = batch
                    break

        if best_batch:
            # Create folder structure
            date_folder = os.path.join(output_base, best_batch['date'])
            batch_folder = os.path.join(date_folder, f"Batch_{best_batch['batch']}")

            os.makedirs(batch_folder, exist_ok=True)

            # Move file
            new_path = os.path.join(batch_folder, file)
            shutil.copy2(path, new_path)

            status = "✓ MOVED"
            moved_count += 1
        else:
            status = "✗ NO BATCH"
            batch_folder = "No Match"

        print(f"{file:<30} {file_date_fmt} {file_time:<20} {best_batch['batch'] if best_batch else 'N/A':<10} {batch_folder[-40:]:<50} {status:<10}")

    except Exception as e:
        print(f"{file:<30} ERROR: {str(e)[:20]:<20}")

print("=" * 100)
print(f"\n✅ Organized: {moved_count} / {len(files_list)} files")
print(f"📁 Output folder: {output_base}")
