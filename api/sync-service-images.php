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
    $baseUrl = "https://digitrixmedia.com/mahamaintainpro/assets/services/";

    // Get all services with their categories
    $query = "SELECT s.id, s.name, sc.name as category_name
              FROM services s
              JOIN service_categories sc ON s.category_id = sc.id
              WHERE s.is_active = 1
              ORDER BY s.id ASC";
    $result = $conn->query($query);

    $synced = 0;
    $missing = 0;
    $syncedServices = [];
    $missingServices = [];

    while ($row = $result->fetch_assoc()) {
        $serviceId = $row['id'];
        $serviceName = $row['name'];
        $categoryName = $row['category_name'];
        $folderName = strtolower(str_replace(['&', ' '], ['and', '-'], $categoryName));

        // Check multiple image formats
        $imageFormats = ['jpg', 'jpeg', 'png', 'webp'];
        $imageFound = false;
        $imagePath = null;

        foreach ($imageFormats as $format) {
            $fileName = $serviceId . '.' . $format;
            $fullUrl = $baseUrl . $folderName . '/' . $fileName;

            // Check if file exists by trying to access it
            if (@file_get_contents($fullUrl, false, stream_context_create(['http' => ['method' => 'HEAD']]))) {
                $imagePath = $folderName . '/' . $fileName;
                $imageFound = true;
                break;
            }
        }

        if ($imageFound && $imagePath) {
            // Update database
            $updateStmt = $conn->prepare("UPDATE services SET image_path = ? WHERE id = ?");
            $updateStmt->bind_param("si", $imagePath, $serviceId);
            if ($updateStmt->execute()) {
                $synced++;
                $syncedServices[] = [
                    'id' => $serviceId,
                    'name' => $serviceName,
                    'category' => $categoryName,
                    'image_path' => $imagePath
                ];
            }
            $updateStmt->close();
        } else {
            $missing++;
            $missingServices[] = [
                'id' => $serviceId,
                'name' => $serviceName,
                'category' => $categoryName,
                'expected_path' => $folderName . '/' . $serviceId . '.jpg'
            ];
        }
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Service images synced!',
        'synced' => $synced,
        'missing' => $missing,
        'synced_services' => $syncedServices,
        'missing_services' => $missingServices,
        'next_step' => 'Upload images to: ' . $baseUrl . '{category-folder}/{service-id}.jpg'
    ]);

} catch (Exception $e) {
    http_response_code(500);
    error_log($e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
