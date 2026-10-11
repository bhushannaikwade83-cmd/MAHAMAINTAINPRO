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
    echo json_encode(['success' => false, 'message' => 'Database connection failed', 'error' => $conn->connect_error]);
    exit();
}

$steps = [];

try {
    // STEP 1: Check/Create image_path column
    $checkColumn = "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'service_categories' AND COLUMN_NAME = 'image_path'";
    $result = $conn->query($checkColumn);

    if (!$result || $result->num_rows === 0) {
        $alterQuery = "ALTER TABLE service_categories ADD COLUMN image_path VARCHAR(255) NULL DEFAULT NULL";
        if ($conn->query($alterQuery)) {
            $steps[] = ['step' => '1. Column Creation', 'status' => '✅ Created image_path column'];
        } else {
            $steps[] = ['step' => '1. Column Creation', 'status' => '❌ Failed: ' . $conn->error];
        }
    } else {
        $steps[] = ['step' => '1. Column Check', 'status' => '✅ Column already exists'];
    }

    // STEP 2: Check available images
    $servicesPath = __DIR__ . '/../assets/services';
    $availableImages = [];
    $missingImages = [];

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

    foreach ($imageMap as $imageFile => $categoryName) {
        $imagePath = $servicesPath . '/' . $imageFile;
        if (file_exists($imagePath)) {
            $availableImages[] = ['file' => $imageFile, 'category' => $categoryName, 'status' => '✅ Found'];
        } else {
            $missingImages[] = ['file' => $imageFile, 'category' => $categoryName, 'status' => '❌ Not found'];
        }
    }

    $steps[] = [
        'step' => '2. Image Check',
        'status' => count($availableImages) . '/22 images found',
        'available' => $availableImages,
        'missing' => $missingImages
    ];

    // STEP 3: Sync available images to database
    $synced = [];
    $failedSync = [];

    // Get category IDs
    $categoryQuery = "SELECT id, name FROM service_categories WHERE is_active = 1";
    $categoryResult = $conn->query($categoryQuery);
    $categoryMap = [];

    while ($row = $categoryResult->fetch_assoc()) {
        $categoryMap[$row['name']] = $row['id'];
    }

    // Sync images that exist
    foreach ($availableImages as $imageInfo) {
        $imageFile = $imageInfo['file'];
        $categoryName = $imageInfo['category'];
        $categoryId = $categoryMap[$categoryName] ?? null;

        if ($categoryId) {
            $updateStmt = $conn->prepare("UPDATE service_categories SET image_path = ? WHERE id = ?");
            $updateStmt->bind_param("si", $imageFile, $categoryId);
            if ($updateStmt->execute()) {
                $synced[] = ['category' => $categoryName, 'image' => $imageFile, 'status' => '✅ Synced'];
            } else {
                $failedSync[] = ['category' => $categoryName, 'error' => $updateStmt->error];
            }
            $updateStmt->close();
        }
    }

    $steps[] = [
        'step' => '3. Database Sync',
        'status' => count($synced) . ' images synced',
        'synced' => $synced,
        'failed' => $failedSync
    ];

    // Final status
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Setup complete!',
        'steps' => $steps,
        'summary' => [
            'Images Available' => count($availableImages) . '/22',
            'Images Missing' => count($missingImages) . '/22',
            'Database Synced' => count($synced),
            'Next Action' => count($missingImages) > 0 ? 'Upload missing images to /assets/services/' : 'Done! Refresh app'
        ]
    ]);

} catch (Exception $e) {
    http_response_code(500);
    error_log($e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
