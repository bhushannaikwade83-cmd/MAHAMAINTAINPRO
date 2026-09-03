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
    $user_id = intval($_GET['user_id'] ?? $_POST['user_id'] ?? 0);

    if ($user_id <= 0) {
        throw new Exception('User ID required');
    }

    // Check if secretary exists with this user_id
    $stmt = $conn->prepare("SELECT id, secretary_id, user_id, name, phone, status, approval_status, created_at FROM society_secretaries WHERE user_id = ?");
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $secretary = $result->fetch_assoc();
    $stmt->close();

    if (!$secretary) {
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'exists' => false,
            'message' => 'No secretary registration found'
        ]);
        exit();
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'exists' => true,
        'secretary' => $secretary,
        'status' => $secretary['status'],
        'approval_status' => $secretary['approval_status']
    ]);

} catch (Exception $e) {
    http_response_code(400);
    error_log("Check status error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
