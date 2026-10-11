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

    // Drop emoji column from service_categories
    $pdo->exec("ALTER TABLE service_categories DROP COLUMN emoji");

    // Drop emoji column from services
    $pdo->exec("ALTER TABLE services DROP COLUMN emoji");

    echo json_encode([
        'success' => true,
        'message' => '✅ Emoji columns deleted successfully!',
        'dropped_from' => [
            'service_categories',
            'services'
        ]
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>
