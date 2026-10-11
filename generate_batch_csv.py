import os
import json
import csv
from datetime import datetime

# Load student data
with open('/Users/bhushan/Desktop/PROJECTS/maha-maintanpro-main/seat_numbers_data.json', 'r') as f:
    students_data = json.load(f)

# Create dict for quick lookup
students_dict = {s['seat_no']: s for s in students_data}

base_folder = "/Users/bhushan/Downloads/dde2a01c-4ab7-4fdc-ab3d-2fd7819b05ef/2026_Organized"

# Collect all files
all_files = []
for date_folder in os.listdir(base_folder):
    date_path = os.path.join(base_folder, date_folder)
    if not os.path.isdir(date_path) or date_folder.startswith('.'):
        continue

    for batch_folder in os.listdir(date_path):
        batch_path = os.path.join(date_path, batch_folder)
        if not os.path.isdir(batch_path) or batch_folder.startswith('.'):
            continue

        for file in os.listdir(batch_path):
            if file.endswith('.jpg'):
                file_path = os.path.join(batch_path, file)
                file_mtime = os.path.getmtime(file_path)
                file_time = datetime.fromtimestamp(file_mtime)

                # Parse filename
                parts = file.replace('entry_', '').replace('.jpg', '').split('_')
                file_date = parts[0] if len(parts) > 0 else ''
                file_time_str = parts[1] if len(parts) > 1 else ''

                all_files.append({
                    'date': date_folder,
                    'batch': batch_folder,
                    'filename': file,
                    'file_date': file_date,
                    'file_time': file_time_str,
                    'file_path': file_path,
                    'file_size': os.path.getsize(file_path)
                })

# Sort by date and batch
all_files.sort(key=lambda x: (x['date'], x['batch']))

# Create CSV
csv_file = '/Users/bhushan/Desktop/PROJECTS/maha-maintanpro-main/batch_files.csv'
with open(csv_file, 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(['Date', 'Batch', 'Filename', 'File Date', 'File Time', 'File Size (KB)', 'Folder Path'])

    for file_info in all_files:
        writer.writerow([
            file_info['date'],
            file_info['batch'],
            file_info['filename'],
            file_info['file_date'],
            file_info['file_time'],
            round(file_info['file_size'] / 1024, 2),
            file_info['file_path']
        ])

print(f"✅ CSV created: {csv_file}")
print(f"📊 Total files: {len(all_files)}")
print(f"\nFirst 10 files:")
print("=" * 120)
print(f"{'Date':<15} {'Batch':<15} {'Filename':<30} {'File Date':<12} {'File Time':<12} {'Size (KB)':<12}")
print("=" * 120)
for file_info in all_files[:10]:
    print(f"{file_info['date']:<15} {file_info['batch']:<15} {file_info['filename']:<30} {file_info['file_date']:<12} {file_info['file_time']:<12} {round(file_info['file_size']/1024, 2):<12}")

print(f"\n... and {len(all_files) - 10} more files")
