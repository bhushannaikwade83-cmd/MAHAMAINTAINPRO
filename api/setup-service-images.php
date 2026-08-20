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
    // Add image_path column to services table if it doesn't exist
    $checkColumn = "SHOW COLUMNS FROM services LIKE 'image_path'";
    $result = $conn->query($checkColumn);

    if ($result->num_rows == 0) {
        $addColumn = "ALTER TABLE services ADD COLUMN image_path VARCHAR(255) DEFAULT NULL AFTER notes";
        if ($conn->query($addColumn)) {
            $imageAdded = true;
        } else {
            throw new Exception("Error adding image_path column: " . $conn->error);
        }
    } else {
        $imageAdded = false;
    }

    // Get all categories and create folder structure info
    $query = "SELECT id, name FROM service_categories WHERE is_active = 1 ORDER BY id ASC";
    $result = $conn->query($query);

    $categories = [];
    $folders = [];

    while ($row = $result->fetch_assoc()) {
        $categoryId = $row['id'];
        $categoryName = $row['name'];
        $folderName = strtolower(str_replace(['&', ' '], ['and', '-'], $categoryName));

        $categories[] = [
            'id' => $categoryId,
            'name' => $categoryName,
            'folder' => $folderName,
            'path' => "https://digitrixmedia.com/mahamaintainpro/assets/services/$folderName/"
        ];

        $folders[] = $folderName;
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Service images setup complete!',
        'image_column_added' => $imageAdded,
        'folders_to_create' => $folders,
        'categories' => $categories,
        'instructions' => [
            '1. Create this folder structure on your hosting:',
            'public_html/mahamaintainpro/assets/services/',
            '',
            '2. Inside it, create these folders:',
            implode(', ', $folders),
            '',
            '3. Upload service images to respective folders',
            '',
            '4. Use this naming format: service-id.jpg',
            'Example: 1.jpg, 2.jpg, 3.jpg for first 3 services',
            '',
            '5. Run update-service-images.php to sync paths'
        ],
        'example_usage' => [
            'Folder: assets/services/insta-help/',
            'Image: 1.jpg (for service ID 1)',
            'URL: https://digitrixmedia.com/mahamaintainpro/assets/services/insta-help/1.jpg'
        ]
    ]);

} catch (Exception $e) {
    http_response_code(500);
    error_log($e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
