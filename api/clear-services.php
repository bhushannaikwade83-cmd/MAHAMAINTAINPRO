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

    // Delete all services first (foreign key dependency)
    $pdo->exec("TRUNCATE TABLE services");

    // Delete all categories
    $pdo->exec("TRUNCATE TABLE service_categories");

    echo json_encode([
        'success' => true,
        'message' => 'All categories and services deleted successfully',
        'status' => 'Ready to add new services'
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>
