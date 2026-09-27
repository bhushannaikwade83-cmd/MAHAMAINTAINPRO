<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// JWT Authentication (Security Layer)
require_once 'jwt-auth.php';
$authToken = verifyJWTToken();

try {
    $input = json_decode(file_get_contents('php://input'), true);

    if (!$input || empty($input['mpin'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'mpin is required']);
        exit;
    }

    // phone_number from verified JWT, not client input
    $phoneNumber = $authToken['phone_number'];
    $mpin = $input['mpin'];

    if (!preg_match('/^[0-9]{4}$/', $mpin)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'mpin must be 4 digits']);
        exit;
    }

    // Hash the M-PIN using password_hash for security
    $mpinHash = password_hash($mpin, PASSWORD_BCRYPT);

    $conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');

    if ($conn->connect_error) {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => 'Database connection failed']);
        exit;
    }

    // Insert or update M-PIN
    $stmt = $conn->prepare("
        INSERT INTO user_mpin (phone_number, mpin_hash)
        VALUES (?, ?)
        ON DUPLICATE KEY UPDATE
        mpin_hash = ?,
        updated_at = CURRENT_TIMESTAMP
    ");

    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => 'Database error: ' . $conn->error]);
        $conn->close();
        exit;
    }

    $stmt->bind_param("sss", $phoneNumber, $mpinHash, $mpinHash);

    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'M-PIN saved successfully']);
    } else {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => 'Failed to save M-PIN: ' . $stmt->error]);
    }

    $stmt->close();
    $conn->close();
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
