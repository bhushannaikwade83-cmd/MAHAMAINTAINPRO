<?php
header('Content-Type: application/json');

$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);

if ($conn->connect_error) {
    echo json_encode(['error' => 'Connection failed: ' . $conn->connect_error]);
    exit();
}

// Check if ratings table exists
$checkTable = "SHOW TABLES LIKE 'ratings'";
$result = $conn->query($checkTable);
$tableExists = $result && $result->num_rows > 0;

echo json_encode([
    'ratings_table_exists' => $tableExists,
    'step_1' => 'Checking if ratings table exists',
    'step_2' => 'Attempting to create if missing...'
]);

// Try to create the table
$createSQL = "CREATE TABLE IF NOT EXISTS ratings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL UNIQUE,
    vendor_id INT NOT NULL,
    customer_phone VARCHAR(20),
    rating INT,
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)";

if ($conn->query($createSQL)) {
    echo json_encode([
        'success' => true,
        'message' => '✅ Ratings table created/verified',
        'status_before' => $tableExists,
        'status_after' => true
    ]);
} else {
    echo json_encode([
        'success' => false,
        'error' => $conn->error
    ]);
}

$conn->close();
?>
