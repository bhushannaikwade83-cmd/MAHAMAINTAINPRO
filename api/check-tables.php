<?php
header('Content-Type: application/json');

$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['error' => 'DB connection failed: ' . $conn->connect_error]);
    exit();
}

// Check all tables
$result = $conn->query("SHOW TABLES");
$tables = [];
if ($result) {
    while ($row = $result->fetch_row()) {
        $tables[] = $row[0];
    }
}

// Check if ratings table exists
$ratingsExists = in_array('ratings', $tables);

// If not, try to create it
if (!$ratingsExists) {
    $sql = "CREATE TABLE ratings (
        id INT AUTO_INCREMENT PRIMARY KEY,
        order_id VARCHAR(50) NOT NULL UNIQUE,
        vendor_id INT NOT NULL,
        customer_phone VARCHAR(20) NOT NULL,
        rating INT NOT NULL,
        comment TEXT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_vendor_id (vendor_id),
        INDEX idx_customer_phone (customer_phone)
    )";

    if ($conn->query($sql)) {
        $ratingsExists = true;
        $createResult = "✅ Created successfully";
    } else {
        $createResult = "❌ Create failed: " . $conn->error;
    }
} else {
    $createResult = "✅ Already exists";
}

// Get table structure
$tableInfo = [];
if ($ratingsExists) {
    $info = $conn->query("DESCRIBE ratings");
    if ($info) {
        while ($row = $info->fetch_assoc()) {
            $tableInfo[] = $row;
        }
    }
}

echo json_encode([
    'database' => $database,
    'all_tables' => $tables,
    'ratings_exists' => $ratingsExists,
    'ratings_status' => $createResult,
    'ratings_columns' => $tableInfo,
    'timestamp' => date('Y-m-d H:i:s')
], JSON_PRETTY_PRINT);

$conn->close();
?>
