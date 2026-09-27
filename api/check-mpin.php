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
    $phoneNumber = $_GET['phone_number'] ?? '';

    if (empty($phoneNumber)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'phone_number parameter is required']);
        exit;
    }

    $conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');

    if ($conn->connect_error) {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => 'Database connection failed']);
        exit;
    }

    // Check if M-PIN exists for the phone number
    $stmt = $conn->prepare("SELECT id FROM user_mpin WHERE phone_number = ? LIMIT 1");

    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => 'Database error: ' . $conn->error]);
        $conn->close();
        exit;
    }

    $stmt->bind_param("s", $phoneNumber);
    $stmt->execute();
    $result = $stmt->get_result();

    $exists = $result->num_rows > 0;

    echo json_encode([
        'success' => true,
        'exists' => $exists,
        'phone_number' => $phoneNumber
    ]);

    $stmt->close();
    $conn->close();
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
