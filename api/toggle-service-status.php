<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

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
    $input = json_decode(file_get_contents('php://input'), true);

    $service_id = $input['service_id'] ?? null;
    $is_active = isset($input['is_active']) ? (int)$input['is_active'] : null;

    if (is_null($service_id) || is_null($is_active)) {
        throw new Exception('Service ID and is_active status required');
    }

    $stmt = $conn->prepare("UPDATE society_services SET is_active = ? WHERE id = ?");
    $stmt->bind_param("ii", $is_active, $service_id);
    $stmt->execute();

    if ($stmt->affected_rows === 0) {
        throw new Exception('Service not found');
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => $is_active ? 'Service activated' : 'Service deactivated',
        'service_id' => $service_id,
        'is_active' => $is_active
    ]);

} catch (Exception $e) {
    http_response_code(400);
    error_log("Toggle service error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
