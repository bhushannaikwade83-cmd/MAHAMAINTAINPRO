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

    if (!isset($data['category_id']) || !isset($data['name'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Category ID and name are required']);
        exit;
    }

    $stmt = $pdo->prepare("
        INSERT INTO services (category_id, name, price, duration, rating, notes, image_path, is_active)
        VALUES (?, ?, ?, ?, ?, ?, ?, 1)
    ");

    $stmt->execute([
        $data['category_id'],
        $data['name'],
        $data['price'] ?? 0,
        $data['duration'] ?? '1 hour',
        $data['rating'] ?? 5,
        $data['notes'] ?? '',
        $data['image_path'] ?? NULL,
    ]);

    $serviceId = $pdo->lastInsertId();

    echo json_encode([
        'success' => true,
        'message' => 'Service added successfully',
        'id' => $serviceId,
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
