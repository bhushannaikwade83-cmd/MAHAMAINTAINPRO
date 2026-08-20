<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit();
}

try {
    // Available images from laptop
    $localImages = [
        'ac_repair.jpeg' => 'AC & Appliance Repair',
        'blood_testing.jpeg' => 'Blood Testing',
        'car_repair.jpeg' => 'Vehicle Care',
        'cleaning.jpeg' => 'Professional Cleaning',
        'cook.jpeg' => 'Food & Catering',
        'electrician.jpeg' => 'Electrician Plumber Carpenter',
        'festival_services.jpeg' => 'Festival Services',
        'fire_safety.jpeg' => 'Fire Safety',
        'healthcare.jpeg' => 'Health & Care',
        'home_services.jpeg' => 'Insta Help',
        'interior_designer.jpeg' => 'Interior Designer',
        'mens_salon.jpeg' => 'Men\'s Salon & Massage',
        'painting.jpeg' => 'Home Painting',
        'pest_control.jpeg' => 'Pest Control',
        'plumber.jpeg' => 'Electrician Plumber Carpenter',
        'pooja_services.jpeg' => 'Pooja Services',
        'real_estate.jpeg' => 'Real Estate',
        'smart_society.jpeg' => 'Smart Society Hub',
        'toursandtravels.png' => 'Tours & Travels',
        'water_testing.jpeg' => 'Water Testing',
        'waterproofing.jpeg' => 'Water Proofing',
        'weekly_baxar.jpeg' => 'Weekly Bazar',
        'womens_saloon.jpeg' => 'Women\'s Salon & Spa'
    ];

    // Get all categories from database
    $query = "SELECT id, name FROM service_categories WHERE is_active = 1 ORDER BY name ASC";
    $result = $conn->query($query);

    $matching = [];
    $unmatched = [];
    $matchedCount = 0;

    while ($row = $result->fetch_assoc()) {
        $categoryId = $row['id'];
        $categoryName = $row['name'];
        $matched = false;

        // Try to find matching image
        foreach ($localImages as $imageName => $imageCategoryName) {
            if (strtolower($imageCategoryName) === strtolower($categoryName)) {
                $matching[] = [
                    'category_id' => $categoryId,
                    'category_name' => $categoryName,
                    'image_file' => $imageName,
                    'image_category' => $imageCategoryName,
                    'status' => '✅ MATCHED',
                    'action' => 'UPLOAD'
                ];
                $matched = true;
                $matchedCount++;
                break;
            }
        }

        if (!$matched) {
            $unmatched[] = [
                'category_id' => $categoryId,
                'category_name' => $categoryName,
                'image_file' => null,
                'status' => '❌ NO IMAGE',
                'action' => 'NEEDS IMAGE'
            ];
        }
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'total_categories' => $matchedCount + count($unmatched),
        'matched' => $matchedCount,
        'unmatched' => count($unmatched),
        'summary' => $matchedCount . ' of ' . ($matchedCount + count($unmatched)) . ' categories have images',
        'matched_table' => $matching,
        'unmatched_table' => $unmatched,
        'next_step' => 'Review above table. If correct, run sync-images.php to upload'
    ]);

} catch (Exception $e) {
    http_response_code(500);
    error_log($e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
