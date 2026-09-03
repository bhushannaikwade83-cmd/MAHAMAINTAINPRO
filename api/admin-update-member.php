<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        http_response_code(405);
        echo json_encode(['success' => false, 'error' => 'POST required']);
        exit;
    }

    $data = json_decode(file_get_contents('php://input'), true);

    if (!isset($data['user_id']) || !isset($data['field']) || !isset($data['value'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Missing parameters']);
        exit;
    }

    $user_id = (int)$data['user_id'];
    $field = $data['field']; // 'is_enabled' or 'is_committee'
    $value = (int)$data['value'];

    // Validate field
    if (!in_array($field, ['is_enabled', 'is_committee'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Invalid field']);
        exit;
    }

    $conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');

    if ($conn->connect_error) {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => 'Database connection failed']);
        exit;
    }

    // Update the field
    $query = "UPDATE society_customers_individual SET $field = $value WHERE user_id = $user_id";

    if (!$conn->query($query)) {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => $conn->error]);
        exit;
    }

    // If enabling, also update secretary status
    if ($field === 'is_enabled' && $value === 1) {
        $conn->query("UPDATE society_secretaries SET approval_status = 'approved' WHERE user_id = $user_id");
    }

    echo json_encode([
        'success' => true,
        'message' => "Member $field updated successfully",
        'user_id' => $user_id,
        'field' => $field,
        'value' => $value
    ]);

    $conn->close();
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
