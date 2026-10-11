import requests
import json

SUPABASE_URL = "https://snxcrqgodamoxwgkkqez.supabase.co"
API_KEY = "sb_publishable_qZd_MA-TbJ7CO1pRkp_P9Q_CuC1CdmL"

seat_numbers = """1401160025
1401160044
1401160074
1401150344
1513150163
1513150172
1503160121
1504150374
1507160069
1507150076
1507150090
1302160058
1302160060
1303150108
1303160008
1201250103
1101250051
1302260019
1402250195
1507250105
1507250067
1503260014
2106150258
2109150182
2101160205
2102160161
2102150509
2107160696
2107150542
2107150688
2202160019
2205150137
2201150804
2201151056
2201151100
2201151101
2201160108
2201160001
2201160672
2305150155
2305150065
2306150188
2306150562
2306160032
2306160112
2306160188
2306160229
2107250001
2102250434
2107250102
2107250211
2101250270
2206260042
2301250184
3101150661
3101150730
3101150789
3101151005
3104250028
3101250328
3101250211
3304250015
3304250020
4105150202
4105160056
4105160066
4105160121
4105160128
4304150018
4302150230
4402160008
4305150069
4305160278
4110250285
4401250001
4301250071
5503260069
6102160216
6302160262
6502160113
7101160071
7103160386
7201160072
7503160107
7201250083
8206250232
8302250006
8303250352
8303250386
8302250372
8303250375
8302250309
8302250303
8302250331
8303250147
8302250368
8303260034
8203160026
8303160500
8303160098
8303160274
8303160024
8303160191
8303160197
8303160457
8303160537
8303160496
8303160521
8303160240""".strip().split('\n')

print(f"Fetching data for {len(seat_numbers)} students...\n")
print(f"{'Seat No':<15} {'Student Name':<40} {'Entry Photo At':<25} {'Status':<10}")
print("=" * 90)

headers = {
    "apikey": API_KEY,
    "Content-Type": "application/json"
}

# Fetch each student
students = []
for seat_no in seat_numbers:
    url = f"{SUPABASE_URL}/rest/v1/exam_students?seat_no=eq.{seat_no}&select=seat_no,student_name,photo_url,entry_photo_at,entry_photo_url,exam_date,subject_name,batch,start_time,end_time"

    try:
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            data = response.json()
            if data:
                student = data[0]
                students.append(student)
                entry_photo_at = student.get('entry_photo_at', 'N/A')
                print(f"{seat_no:<15} {student.get('student_name', 'N/A')[:40]:<40} {str(entry_photo_at)[:25]:<25} {'✓':<10}")
            else:
                print(f"{seat_no:<15} {'Not found':<40} {'N/A':<25} {'✗':<10}")
        else:
            print(f"{seat_no:<15} {'Error':<40} {'N/A':<25} {'✗':<10}")
    except Exception as e:
        print(f"{seat_no:<15} {'Exception':<40} {'N/A':<25} {'✗':<10}")

print(f"\n✅ Fetched {len(students)} students\n")

# Save to JSON
output_file = "/Users/bhushan/Desktop/PROJECTS/maha-maintanpro-main/seat_numbers_data.json"
with open(output_file, 'w') as f:
    json.dump(students, f, indent=2)

print(f"📁 Saved to: {output_file}")

# Show sample
if students:
    print(f"\nFirst student sample:")
    print(json.dumps(students[0], indent=2)[:500])
