<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit();
}

try {
    // Create society_customers_individual table
    $createTable = "CREATE TABLE IF NOT EXISTS society_customers_individual (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL UNIQUE,
        is_committee BOOLEAN DEFAULT 0,
        is_enabled BOOLEAN DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        KEY idx_user_id (user_id),
        KEY idx_is_committee (is_committee),
        KEY idx_is_enabled (is_enabled),
        FOREIGN KEY (user_id) REFERENCES individuals(id) ON DELETE CASCADE
    )";

    if (!$conn->query($createTable)) {
        throw new Exception("Failed to create table: " . $conn->error);
    }

    echo json_encode([
        'success' => true,
        'message' => 'society_customers_individual table created successfully',
        'table_structure' => [
            'user_id' => 'INT - links to individuals table',
            'is_committee' => 'BOOLEAN - 1=committee member, 0=regular member',
            'is_enabled' => 'BOOLEAN - 1=access granted, 0=access blocked',
            'created_at' => 'TIMESTAMP - when added to society',
            'updated_at' => 'TIMESTAMP - last modified'
        ]
    ]);

} catch (Exception $e) {
    http_response_code(500);
    error_log("Migration error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
