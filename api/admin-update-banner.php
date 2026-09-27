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

try {
    $conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');
    if ($conn->connect_error) {
        throw new Exception('Database connection failed');
    }

    $data = json_decode(file_get_contents('php://input'), true);
    $id = intval($data['id'] ?? 0);
    if ($id <= 0) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'id is required']);
        exit;
    }

    $fields = ['title' => 's', 'image_path' => 's', 'link_type' => 's', 'link_value' => 's', 'sort_order' => 'i', 'is_active' => 'i'];
    $updates = [];
    $params = [];
    $types = '';
    foreach ($fields as $field => $type) {
        if (array_key_exists($field, $data)) {
            $updates[] = "$field = ?";
            $params[] = $type === 'i' ? (int)$data[$field] : $data[$field];
            $types .= $type;
        }
    }

    if (empty($updates)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'No fields to update']);
        exit;
    }

    $params[] = $id;
    $types .= 'i';
    $stmt = $conn->prepare("UPDATE banners SET " . implode(', ', $updates) . " WHERE id = ?");
    $stmt->bind_param($types, ...$params);
    $stmt->execute();

    echo json_encode(['success' => true, 'message' => 'Banner updated successfully']);
    $stmt->close();
    $conn->close();
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
