<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'jwt-auth.php';
requireAdminRole();

$data = json_decode(file_get_contents('php://input'), true);
$id = intval($data['id'] ?? 0);
$approval_status = $data['approval_status'] ?? null; // 'approved' | 'rejected' | 'pending'

if ($id <= 0 || !in_array($approval_status, ['approved', 'rejected', 'pending'], true)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'id and a valid approval_status are required']);
    exit;
}

try {
    $conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');
    if ($conn->connect_error) {
        throw new Exception('Database connection failed');
    }

    $status = $approval_status === 'approved' ? 'active' : 'not_active';
    $stmt = $conn->prepare("UPDATE society_secretaries SET approval_status = ?, status = ?, updated_at = NOW() WHERE id = ?");
    $stmt->bind_param('ssi', $approval_status, $status, $id);
    $stmt->execute();

    if ($stmt->affected_rows === 0) {
        http_response_code(404);
        echo json_encode(['success' => false, 'error' => 'Secretary registration not found']);
        exit;
    }

    echo json_encode(['success' => true, 'message' => "Secretary registration $approval_status"]);
    $stmt->close();
    $conn->close();
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
