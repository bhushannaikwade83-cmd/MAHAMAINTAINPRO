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

    // Check categories with image_path
    $stmt = $pdo->query("SELECT id, name, image_path FROM service_categories LIMIT 10");
    $categories = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Check files in uploads directory
    $uploadsDir = __DIR__ . '/../uploads/services/';
    $files = [];
    if (is_dir($uploadsDir)) {
        $files = array_diff(scandir($uploadsDir), ['.', '..']);
    }

    echo json_encode([
        'success' => true,
        'categories_with_image_path' => $categories,
        'uploaded_files' => $files,
        'uploads_dir_exists' => is_dir($uploadsDir),
        'message' => 'Check database image_path values'
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
