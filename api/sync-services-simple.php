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
    // Image mappings
    $imageMap = [
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
        'pooja_services.jpeg' => 'Pooja Services',
        'real_estate.jpeg' => 'Real Estate',
        'smart_society.jpeg' => 'Smart Society Hub',
        'toursandtravels.png' => 'Tours & Travels',
        'water_testing.jpeg' => 'Water Testing',
        'waterproofing.jpeg' => 'Water Proofing',
        'weekly_baxar.jpeg' => 'Weekly Bazar',
        'womens_saloon.jpeg' => 'Women\'s Salon & Spa'
    ];

    $servicesPath = __DIR__ . '/../assets/services';

    $synced = [];
    $failed = [];
    $totalSize = 0;

    // Get category IDs from database
    $categoryQuery = "SELECT id, name FROM service_categories WHERE is_active = 1";
    $categoryResult = $conn->query($categoryQuery);
    $categoryMap = [];

    while ($row = $categoryResult->fetch_assoc()) {
        $categoryMap[$row['name']] = $row['id'];
    }

    // Process each image in imageMap
    foreach ($imageMap as $imageFile => $categoryName) {
        $imagePath = $servicesPath . '/' . $imageFile;
        $categoryId = $categoryMap[$categoryName] ?? null;

        if (!$categoryId) {
            $failed[] = [
                'image' => $imageFile,
                'category' => $categoryName,
                'error' => 'Category not found in database'
            ];
            continue;
        }

        if (file_exists($imagePath)) {
            $fileSize = filesize($imagePath);
            $totalSize += $fileSize;

            // Update database with image path
            $updateStmt = $conn->prepare("UPDATE service_categories SET image_path = ? WHERE id = ?");
            $updateStmt->bind_param("si", $imageFile, $categoryId);
            $updateStmt->execute();
            $updateStmt->close();

            $synced[] = [
                'image' => $imageFile,
                'category' => $categoryName,
                'size_kb' => round($fileSize / 1024, 2),
                'status' => '✅ Synced'
            ];
        } else {
            $failed[] = [
                'image' => $imageFile,
                'category' => $categoryName,
                'error' => 'Image file not found in /assets/services/'
            ];
        }
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Service images synced!',
        'synced' => count($synced),
        'failed' => count($failed),
        'total_size_mb' => round($totalSize / (1024 * 1024), 2),
        'synced_list' => $synced,
        'failed_list' => $failed,
        'next_step' => 'Update Flutter UI to display images from database'
    ]);

} catch (Exception $e) {
    http_response_code(500);
    error_log($e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
