<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$checks = [];

// 1. Check assets/services folder exists
$servicesPath = __DIR__ . '/../assets/services';
$checks['assets_services_folder_exists'] = is_dir($servicesPath);
$checks['assets_services_path'] = $servicesPath;

// 2. List files in assets/services
if (is_dir($servicesPath)) {
    $files = scandir($servicesPath);
    $images = array_filter($files, function($file) use ($servicesPath) {
        $filePath = $servicesPath . '/' . $file;
        return is_file($filePath) && in_array(strtolower(pathinfo($file, PATHINFO_EXTENSION)), ['jpg', 'jpeg', 'png', 'webp']);
    });
    $checks['image_files_found'] = count($images);
    $checks['images_list'] = array_values($images);
} else {
    $checks['images_list'] = [];
}

// 3. Check database connection
$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);

if ($conn->connect_error) {
    $checks['database_connected'] = false;
    $checks['database_error'] = $conn->connect_error;
} else {
    $checks['database_connected'] = true;

    // Check service_categories table
    $result = $conn->query("SELECT COUNT(*) as total, SUM(CASE WHEN image_path IS NOT NULL THEN 1 ELSE 0 END) as with_images FROM service_categories WHERE is_active = 1");
    $row = $result->fetch_assoc();
    $checks['categories_total'] = $row['total'];
    $checks['categories_with_images'] = $row['with_images'];
}

$checks['php_version'] = phpversion();
$checks['timestamp'] = date('Y-m-d H:i:s');

http_response_code(200);
echo json_encode($checks, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
$conn->close();
?>
