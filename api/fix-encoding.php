<?php
header('Content-Type: application/json; charset=utf-8');

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

    // Fix table collation
    $pdo->exec("ALTER TABLE service_categories CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
    $pdo->exec("ALTER TABLE services CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");

    // Get all categories and services to check them
    $stmt = $pdo->query("SELECT id, name, emoji FROM service_categories ORDER BY id");
    $categories = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $stmt = $pdo->query("SELECT id, name, emoji, category_id FROM services ORDER BY id");
    $services = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'message' => 'Database encoding fixed',
        'tables_fixed' => [
            'service_categories',
            'services'
        ],
        'categories' => $categories,
        'services' => $services,
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>
