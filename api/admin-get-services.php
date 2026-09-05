<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
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

    // Get all categories
    $categoryStmt = $pdo->query("SELECT id, name, color, description, image_path FROM service_categories ORDER BY id ASC");
    $categories = $categoryStmt->fetchAll(PDO::FETCH_ASSOC);

    // For each category, get its services
    foreach ($categories as &$category) {
        $serviceStmt = $pdo->prepare("SELECT id, name, price, duration, rating, notes, image_path, is_active FROM services WHERE category_id = ? ORDER BY id ASC");
        $serviceStmt->execute([$category['id']]);
        $category['services'] = $serviceStmt->fetchAll(PDO::FETCH_ASSOC);
        $category['service_count'] = count($category['services']);
    }

    echo json_encode([
        'success' => true,
        'categories' => $categories,
        'total_categories' => count($categories),
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
