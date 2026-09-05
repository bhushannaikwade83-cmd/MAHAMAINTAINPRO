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

    // Drop services table first (foreign key)
    $pdo->exec("DROP TABLE IF EXISTS services");

    // Drop service_categories table
    $pdo->exec("DROP TABLE IF EXISTS service_categories");

    // Recreate service_categories table (fresh, clean)
    $pdo->exec("
        CREATE TABLE service_categories (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(255) NOT NULL CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci,
            emoji VARCHAR(50) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci,
            color VARCHAR(50) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci,
            description TEXT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci,
            image_path VARCHAR(500) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci,
            is_active TINYINT DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_active (is_active)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");

    // Recreate services table
    $pdo->exec("
        CREATE TABLE services (
            id INT AUTO_INCREMENT PRIMARY KEY,
            category_id INT NOT NULL,
            name VARCHAR(255) NOT NULL CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci,
            emoji VARCHAR(50) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci,
            price DECIMAL(10, 2) DEFAULT 0,
            duration VARCHAR(100) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci,
            rating INT DEFAULT 5,
            notes TEXT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci,
            image_path VARCHAR(500) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci,
            is_active TINYINT DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (category_id) REFERENCES service_categories(id) ON DELETE CASCADE,
            INDEX idx_category (category_id),
            INDEX idx_active (is_active)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");

    echo json_encode([
        'success' => true,
        'message' => '✅ Tables dropped and recreated fresh!',
        'status' => 'Ready for new data with proper UTF-8 encoding',
        'tables' => [
            'service_categories' => 'Recreated ✓',
            'services' => 'Recreated ✓'
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
