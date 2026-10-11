import subprocess
import json
from collections import defaultdict

print("🔍 Analyzing B2 bucket for entry photos...\n")

# Get all files from B2
result = subprocess.run(
    ["b2", "ls", "--recursive", "b2://attendance-students-photos/"],
    capture_output=True, text=True, timeout=300
)

if result.returncode != 0:
    print(f"Error: {result.stderr}")
    exit(1)

files = result.stdout.strip().split('\n')
print(f"✅ Found {len(files)} total files in B2\n")

# Organize by folder and count entry files
folder_entries = defaultdict(list)
batch_folders = defaultdict(int)

for file_path in files:
    if not file_path:
        continue

    # Extract folder path (everything except filename)
    parts = file_path.rsplit('/', 1)
    if len(parts) == 2:
        folder, filename = parts
        batch_folders[folder] += 1

        if 'entry' in filename.lower():
            folder_entries[folder].append(filename)

# Find folders with entry photos
entry_folders = {k: v for k, v in folder_entries.items() if v}

print("=" * 150)
print(f"{'Folder Path':<100} {'Entry Files':<20} {'Total Files':<20}")
print("=" * 150)

sorted_folders = sorted(entry_folders.items(), key=lambda x: len(x[1]), reverse=True)

for folder, entries in sorted_folders:
    entry_count = len(entries)
    total_count = batch_folders[folder]
    print(f"{folder:<100} {entry_count:<20} {total_count:<20}")

print("=" * 150)
print(f"\n📊 Summary:")
print(f"   Total folders with 'entry' files: {len(entry_folders)}")
print(f"   Total 'entry' files across all folders: {sum(len(v) for v in entry_folders.values())}")

# Find folders with exactly 10 or more entry photos
high_entry_folders = {k: len(v) for k, v in entry_folders.items() if len(v) >= 10}
print(f"\n🎯 Folders with 10+ entry photos: {len(high_entry_folders)}")
for folder, count in sorted(high_entry_folders.items(), key=lambda x: x[1], reverse=True):
    print(f"   {folder.split('/')[-1]} → {count} entry photos")
