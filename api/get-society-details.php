<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Public read of one society's own details (name/address/registration/
// contact) - residents need this and shouldn't require admin role.
$id = (int)($_GET['id'] ?? 0);
if ($id <= 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'id is required']);
    exit;
}

try {
    $conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');
    if ($conn->connect_error) {
        throw new Exception('Database connection failed');
    }

    $stmt = $conn->prepare("SELECT id, name, address, city, postal_code, registration_number, registration_date, contact_phone, contact_email, created_at FROM societies WHERE id = ?");
    $stmt->bind_param('i', $id);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        echo json_encode(['success' => true, 'society' => null]);
    } else {
        echo json_encode(['success' => true, 'society' => $result->fetch_assoc()]);
    }

    $stmt->close();
    $conn->close();
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
