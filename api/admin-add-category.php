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

    if (!isset($data['name'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Category name is required']);
        exit;
    }

    $stmt = $pdo->prepare("
        INSERT INTO service_categories (name, color, description, image_path, is_active)
        VALUES (?, ?, ?, ?, 1)
    ");

    $stmt->execute([
        $data['name'],
        $data['color'] ?? '#3B82F6',
        $data['description'] ?? '',
        $data['image_path'] ?? NULL,
    ]);

    $categoryId = $pdo->lastInsertId();

    echo json_encode([
        'success' => true,
        'message' => 'Category added successfully',
        'id' => $categoryId,
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
