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

    $name = trim($input['name'] ?? '');
    $phone = trim($input['phone'] ?? '');
    $user_id = intval($input['user_id'] ?? 0);

    if (empty($name) || empty($phone)) {
        throw new Exception('Name and phone are required');
    }

    if (!preg_match('/^[0-9]{10}$/', $phone)) {
        throw new Exception('Phone must be 10 digits');
    }

    if ($user_id <= 0) {
        throw new Exception('User ID is required');
    }

    $secretary_id = 'SEC' . time();

    $stmt = $conn->prepare("INSERT INTO society_secretaries (secretary_id, user_id, name, phone, status, approval_status)
                            VALUES (?, ?, ?, ?, 'not_active', 'pending')");
    $stmt->bind_param("siss", $secretary_id, $user_id, $name, $phone);
    $stmt->execute();

    http_response_code(201);
    echo json_encode([
        'success' => true,
        'message' => 'Registration submitted. Awaiting admin approval.',
        'secretary_id' => $secretary_id,
        'status' => 'pending'
    ]);

} catch (Exception $e) {
    http_response_code(400);
    error_log("Registration error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
