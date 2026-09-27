<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'jwt-auth.php';
requireAdminRole();

try {
    $conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');
    if ($conn->connect_error) {
        throw new Exception('Database connection failed');
    }

    $result = $conn->query("
        SELECT s.id, s.secretary_id, s.society_id, so.name AS society_name, s.user_id,
               s.name, s.phone, s.status, s.approval_status, s.created_at, s.updated_at
        FROM society_secretaries s
        LEFT JOIN societies so ON so.id = s.society_id
        ORDER BY s.created_at DESC
    ");

    $secretaries = [];
    while ($row = $result->fetch_assoc()) {
        $secretaries[] = $row;
    }

    echo json_encode(['success' => true, 'secretaries' => $secretaries, 'total' => count($secretaries)]);
    $conn->close();
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
