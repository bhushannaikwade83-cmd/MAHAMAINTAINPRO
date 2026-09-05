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
    $pdo = new PDO(
        "mysql:host=localhost;dbname=digitrix_maha_maintain_pro;charset=utf8mb4",
        "digitrix_maha_user",
        "maha_user@70",
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4"
        ]
    );

    $data = json_decode(file_get_contents('php://input'), true);

    if (!isset($data['id'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Service ID is required']);
        exit;
    }

    $updates = [];
    $params = [];

    if (isset($data['name'])) {
        $updates[] = 'name = ?';
        $params[] = $data['name'];
    }
    if (isset($data['price'])) {
        $updates[] = 'price = ?';
        $params[] = $data['price'];
    }
    if (isset($data['duration'])) {
        $updates[] = 'duration = ?';
        $params[] = $data['duration'];
    }
    if (isset($data['rating'])) {
        $updates[] = 'rating = ?';
        $params[] = $data['rating'];
    }
    if (isset($data['notes'])) {
        $updates[] = 'notes = ?';
        $params[] = $data['notes'];
    }
    if (isset($data['image_path'])) {
        $updates[] = 'image_path = ?';
        $params[] = $data['image_path'];
    }
    if (isset($data['is_active'])) {
        $updates[] = 'is_active = ?';
        $params[] = $data['is_active'] ? 1 : 0;
    }

    if (empty($updates)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'No fields to update']);
        exit;
    }

    $params[] = $data['id'];
    $query = "UPDATE services SET " . implode(', ', $updates) . " WHERE id = ?";
    $stmt = $pdo->prepare($query);
    $stmt->execute($params);

    if ($stmt->rowCount() === 0) {
        http_response_code(404);
        echo json_encode(['success' => false, 'error' => 'Service not found']);
        exit;
    }

    echo json_encode([
        'success' => true,
        'message' => 'Service updated successfully',
        'id' => $data['id'],
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
