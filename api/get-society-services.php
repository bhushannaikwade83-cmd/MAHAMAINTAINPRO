<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
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
    $secretary_id = $_GET['secretary_id'] ?? '';

    if (empty($secretary_id)) {
        throw new Exception('Secretary ID required');
    }

    // Get secretary info
    $stmt = $conn->prepare("SELECT id, secretary_id, name, status, approval_status FROM society_secretaries WHERE secretary_id = ?");
    $stmt->bind_param("s", $secretary_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $secretary = $result->fetch_assoc();
    $stmt->close();

    if (!$secretary) {
        throw new Exception('Secretary not found');
    }

    // Get society services
    $stmt = $conn->prepare("SELECT id, service_name, service_icon, is_active FROM society_services WHERE secretary_id = ?");
    $stmt->bind_param("s", $secretary_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $services = [];
    while ($row = $result->fetch_assoc()) {
        $services[] = $row;
    }
    $stmt->close();

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'secretary' => $secretary,
        'services' => $services
    ]);

} catch (Exception $e) {
    http_response_code(400);
    error_log("Get services error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
