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

try {
    // Check if image_path column exists
    $checkQuery = "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'service_categories' AND COLUMN_NAME = 'image_path'";
    $result = $conn->query($checkQuery);

    if ($result && $result->num_rows === 0) {
        // Column doesn't exist, create it
        $alterQuery = "ALTER TABLE service_categories ADD COLUMN image_path VARCHAR(255) NULL DEFAULT NULL";

        if ($conn->query($alterQuery)) {
            echo json_encode([
                'success' => true,
                'message' => '✅ image_path column created successfully!',
                'next_step' => 'Now run: https://digitrixmedia.com/mahamaintainpro/api/sync-services-simple.php'
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Failed to create column',
                'error' => $conn->error
            ]);
        }
    } else {
        echo json_encode([
            'success' => true,
            'message' => '✅ image_path column already exists!',
            'next_step' => 'Now run: https://digitrixmedia.com/mahamaintainpro/api/sync-services-simple.php'
        ]);
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
