<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Admin-only: this is a one-time schema migration, not a resident-facing endpoint.
require_once 'jwt-auth.php';
requireAdminRole();

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
    // Create individuals table
    $createTable = "CREATE TABLE IF NOT EXISTS individuals (
        id INT AUTO_INCREMENT PRIMARY KEY,
        phone_number VARCHAR(20) UNIQUE NOT NULL,
        full_name VARCHAR(255),
        email VARCHAR(255),
        profile_picture_url VARCHAR(500),
        role VARCHAR(50) DEFAULT 'individual',
        address_count INT DEFAULT 0,
        is_active BOOLEAN DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY unique_phone (phone_number),
        UNIQUE KEY unique_email (email)
    )";

    if (!$conn->query($createTable)) {
        throw new Exception("Create individuals table failed: " . $conn->error);
    }

    // Verify table structure
    $checkTable = "DESCRIBE individuals";
    $result = $conn->query($checkTable);
    $columns = [];
    while ($row = $result->fetch_assoc()) {
        $columns[] = $row['Field'];
    }

    $messages = [
        'table_created' => true,
        'columns' => $columns,
    ];

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Migration completed successfully',
        'details' => $messages,
        'status' => [
            'individuals_table' => 'Created ✓',
            'phone_number_column' => in_array('phone_number', $columns) ? 'Exists ✓' : 'Missing ✗',
            'email_column' => in_array('email', $columns) ? 'Exists ✓' : 'Missing ✗',
            'full_name_column' => in_array('full_name', $columns) ? 'Exists ✓' : 'Missing ✗',
        ]
    ]);

} catch (Exception $e) {
    http_response_code(400);
    error_log("Migration error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'An internal error occurred. Please try again.']);
}

$conn->close();
?>
