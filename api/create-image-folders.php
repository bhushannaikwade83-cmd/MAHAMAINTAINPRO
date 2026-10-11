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
    // Get all categories
    $query = "SELECT id, name FROM service_categories WHERE is_active = 1 ORDER BY id ASC";
    $result = $conn->query($query);

    $basePath = __DIR__ . '/../assets/services';

    // Create main services folder if it doesn't exist
    if (!is_dir($basePath)) {
        mkdir($basePath, 0755, true);
    }

    $createdFolders = [];
    $failedFolders = [];

    while ($row = $result->fetch_assoc()) {
        $categoryName = $row['name'];
        $folderName = strtolower(str_replace(['&', ' '], ['and', '-'], $categoryName));
        $folderPath = $basePath . '/' . $folderName;

        // Create folder for each category
        if (!is_dir($folderPath)) {
            if (mkdir($folderPath, 0755, true)) {
                // Create placeholder file
                file_put_contents($folderPath . '/README.txt',
                    "Upload service images here\n" .
                    "Naming format: {service-id}.jpg\n" .
                    "Example: 1.jpg, 2.jpg, 3.jpg\n\n" .
                    "Category: $categoryName");

                $createdFolders[] = [
                    'category' => $categoryName,
                    'folder' => $folderName,
                    'path' => 'assets/services/' . $folderName . '/'
                ];
            } else {
                $failedFolders[] = $folderName;
            }
        } else {
            $createdFolders[] = [
                'category' => $categoryName,
                'folder' => $folderName,
                'path' => 'assets/services/' . $folderName . '/',
                'status' => 'already exists'
            ];
        }
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Service image folders created!',
        'base_path' => $basePath,
        'created_count' => count($createdFolders),
        'failed_count' => count($failedFolders),
        'created_folders' => $createdFolders,
        'failed_folders' => $failedFolders,
        'next_step' => 'Upload images to each folder using naming format: {service-id}.jpg',
        'then_run' => 'https://digitrixmedia.com/mahamaintainpro/api/sync-service-images.php'
    ]);

} catch (Exception $e) {
    http_response_code(500);
    error_log($e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
