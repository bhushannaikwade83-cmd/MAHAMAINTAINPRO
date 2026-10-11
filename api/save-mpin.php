<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $input = json_decode(file_get_contents('php://input'), true);

    if (!$input || empty($input['phone_number']) || empty($input['mpin'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'phone_number and mpin are required']);
        exit;
    }

    $phoneNumber = $input['phone_number'];
    $mpin = $input['mpin'];

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
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
