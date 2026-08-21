<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);

if ($conn->connect_error) {
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit();
}

try {
    // Get all categories with their image paths
    $query = "SELECT id, name, image_path FROM service_categories WHERE is_active = 1 ORDER BY name ASC";
    $result = $conn->query($query);

    $categories = [];
    $servicesPath = __DIR__ . '/../assets/services';
    $uploadsPath = __DIR__ . '/../uploads';

    while ($row = $result->fetch_assoc()) {
        $imagePath = $row['image_path'];
        $categoryName = $row['name'];

        $status = '❌ NOT FOUND';
        $location = 'N/A';
        $fileSize = 0;

        // Check in assets/services
        if ($imagePath) {
            $fullPath = $servicesPath . '/' . $imagePath;
            if (file_exists($fullPath)) {
                $status = '✅ LOADED (assets/services)';
                $location = $fullPath;
                $fileSize = filesize($fullPath);
            } else {
                // Check in uploads folder
                $uploadPath = $uploadsPath . '/' . $imagePath;
                if (file_exists($uploadPath)) {
                    $status = '✅ LOADED (uploads)';
                    $location = $uploadPath;
                    $fileSize = filesize($uploadPath);
                }
            }
        }

        $categories[] = [
            'id' => $row['id'],
            'name' => $categoryName,
            'image_path' => $imagePath,
            'status' => $status,
            'file_size_kb' => round($fileSize / 1024, 2),
            'url' => $imagePath ? 'https://digitrixmedia.com/mahamaintainpro/assets/services/' . $imagePath : null
        ];
    }

    // Count loaded and missing
    $loaded = count(array_filter($categories, fn($c) => strpos($c['status'], '✅') === 0));
    $missing = count($categories) - $loaded;

    echo json_encode([
        'success' => true,
        'total_categories' => count($categories),
        'loaded' => $loaded,
        'missing' => $missing,
        'categories' => $categories
    ]);

} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
