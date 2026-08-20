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

    $baseSourcePath = __DIR__ . '/../assets/images/categories';
    $baseDestPath = __DIR__ . '/../assets/services';

    $uploaded = [];
    $failed = [];
    $totalSize = 0;

    // Get category IDs from database
    $categoryQuery = "SELECT id, name FROM service_categories WHERE is_active = 1";
    $categoryResult = $conn->query($categoryQuery);
    $categoryMap = [];

    while ($row = $categoryResult->fetch_assoc()) {
        $categoryMap[$row['name']] = $row['id'];
    }

    // Process each image
    foreach ($imageMap as $imageFile => $categoryName) {
        $sourceFile = $baseSourcePath . '/' . $imageFile;
        $categoryId = $categoryMap[$categoryName] ?? null;

        if (!$categoryId) {
            $failed[] = [
                'image' => $imageFile,
                'category' => $categoryName,
                'error' => 'Category not found in database'
            ];
            continue;
        }

        // Create category-specific folder
        $folderName = strtolower(str_replace(['&', ' '], ['and', '-'], $categoryName));
        $destFolder = $baseDestPath . '/' . $folderName;

        if (!is_dir($destFolder)) {
            mkdir($destFolder, 0755, true);
        }

        $ext = pathinfo($imageFile, PATHINFO_EXTENSION);
        $destFile = $destFolder . '/' . $categoryId . '.' . $ext;

        // Copy image
        if (file_exists($sourceFile)) {
            if (copy($sourceFile, $destFile)) {
                chmod($destFile, 0644);
                $fileSize = filesize($destFile);
                $totalSize += $fileSize;

                $imagePath = $folderName . '/' . $categoryId . '.' . $ext;

                // Update database with image path
                $updateStmt = $conn->prepare("UPDATE service_categories SET image_path = ? WHERE id = ?");
                $updateStmt->bind_param("si", $imagePath, $categoryId);
                $updateStmt->execute();
                $updateStmt->close();

                $uploaded[] = [
                    'image' => $imageFile,
                    'category' => $categoryName,
                    'path' => $imagePath,
                    'size_kb' => round($fileSize / 1024, 2),
                    'status' => 'uploaded'
                ];
            } else {
                $failed[] = [
                    'image' => $imageFile,
                    'category' => $categoryName,
                    'error' => 'Failed to copy file'
                ];
            }
        } else {
            $failed[] = [
                'image' => $imageFile,
                'category' => $categoryName,
                'error' => 'Source file not found'
            ];
        }
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Category images uploaded to server!',
        'uploaded' => count($uploaded),
        'failed' => count($failed),
        'total_size_mb' => round($totalSize / (1024 * 1024), 2),
        'uploaded_list' => $uploaded,
        'failed_list' => $failed,
        'next_step' => 'Images are now live on server. Update app UI to display them.'
    ]);

} catch (Exception $e) {
    http_response_code(500);
    error_log($e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
