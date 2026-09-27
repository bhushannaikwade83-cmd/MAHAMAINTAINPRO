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

    $conn->query("CREATE TABLE IF NOT EXISTS banners (
        id INT AUTO_INCREMENT PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        image_path VARCHAR(500) NOT NULL,
        link_type VARCHAR(50) NULL,
        link_value VARCHAR(255) NULL,
        sort_order INT NOT NULL DEFAULT 0,
        is_active TINYINT(1) NOT NULL DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )");

    $data = json_decode(file_get_contents('php://input'), true);
    if (!isset($data['title']) || !isset($data['image_path'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'title and image_path are required']);
        exit;
    }

    $stmt = $conn->prepare("INSERT INTO banners (title, image_path, link_type, link_value, sort_order, is_active) VALUES (?, ?, ?, ?, ?, ?)");
    $linkType = $data['link_type'] ?? null;
    $linkValue = $data['link_value'] ?? null;
    $sortOrder = (int)($data['sort_order'] ?? 0);
    $isActive = isset($data['is_active']) ? (int)(bool)$data['is_active'] : 1;
    $stmt->bind_param('ssssii', $data['title'], $data['image_path'], $linkType, $linkValue, $sortOrder, $isActive);
    $stmt->execute();

    echo json_encode(['success' => true, 'message' => 'Banner added successfully', 'id' => $stmt->insert_id]);
    $stmt->close();
    $conn->close();
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
