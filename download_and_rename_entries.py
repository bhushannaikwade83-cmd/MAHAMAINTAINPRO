import os
import subprocess
import sys
from pathlib import Path

# B2 bucket details
batch_uuid = "20d55ba5-0495-42a2-b738-efd13939a5bd"
bucket_path = f"b2://attendance-students-photos/{batch_uuid}/2026/"
download_folder = f"/Users/bhushan/Downloads/entry_photos_{batch_uuid}"

# Create folder
os.makedirs(download_folder, exist_ok=True)

print(f"📁 Downloading entry photos from B2...")
print(f"🎯 Target folder: {download_folder}\n")

# Download all entry.jpg files
result = subprocess.run(
    ["b2", "sync", "--compareVersions", "modTime", "--noProgress",
     bucket_path, download_folder],
    capture_output=True, text=True
)

if result.returncode != 0:
    print(f"Error downloading: {result.stderr}")
    sys.exit(1)

# Find all entry.jpg files
entry_files = []
for root, dirs, files in os.walk(download_folder):
    for file in files:
        if file == "entry.jpg":
            entry_files.append(os.path.join(root, file))

print(f"✅ Found {len(entry_files)} entry.jpg files\n")
print("=== RENAMING FILES ===\n")
print(f"{'#':<5} {'From':<30} {'To':<30} {'Folder':<50}")
print("=" * 115)

# Rename files
for idx, file_path in enumerate(sorted(entry_files), 1):
    folder = os.path.dirname(file_path)
    new_name = f"entry{idx}.jpg"
    new_path = os.path.join(folder, new_name)

    try:
        os.rename(file_path, new_path)
        folder_name = folder.split('/')[-1]
        print(f"{idx:<5} {'entry.jpg':<30} {new_name:<30} {folder_name:<50}")
    except Exception as e:
        print(f"{idx:<5} ERROR: {str(e)}")

print(f"\n✅ Renamed {len(entry_files)} files")
print(f"📁 Location: {download_folder}")
