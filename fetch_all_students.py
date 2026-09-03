import requests
import json

SUPABASE_URL = "https://snxcrqgodamoxwgkkqez.supabase.co"
API_KEY = "sb_publishable_qZd_MA-TbJ7CO1pRkp_P9Q_CuC1CdmL"

print(f"Fetching ALL students from exam_students table...\n")
print(f"{'Seat No':<15} {'Student Name':<40} {'Status':<10}")
print("=" * 65)

headers = {
    "apikey": API_KEY,
    "Content-Type": "application/json"
}

# Fetch all students from table
url = f"{SUPABASE_URL}/rest/v1/exam_students?select=seat_no,student_name,photo_url,entry_photo_at,entry_photo_url,exam_date,subject_name,batch,start_time,end_time"

try:
    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        students = response.json()
        print(f"\n✅ Fetched {len(students)} students total\n")

        # Save to JSON
        output_file = "/Users/bhushan/Desktop/PROJECTS/maha-maintanpro-main/students_import.json"
        with open(output_file, 'w') as f:
            json.dump(students, f, indent=2)

        print(f"📁 Saved to: {output_file}")

        # Show sample
        if students:
            print(f"\nFirst student:")
            print(json.dumps(students[0], indent=2))

            # Show summary
            with_photos = sum(1 for s in students if s.get('entry_photo_at'))
            without_photos = len(students) - with_photos
            print(f"\n📊 Summary:")
            print(f"   Total: {len(students)}")
            print(f"   With Photos: {with_photos}")
            print(f"   Without Photos: {without_photos}")
    else:
        print(f"Error: {response.status_code}")
        print(response.text)
except Exception as e:
    print(f"Exception: {str(e)}")
