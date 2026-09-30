<?php
// Run this once to create the completion_otp_storage table

$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

$sql = "CREATE TABLE IF NOT EXISTS completion_otp_storage (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL UNIQUE,
    phone_number VARCHAR(20) NOT NULL,
    otp VARCHAR(10) NOT NULL,
    expires_at DATETIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    verified_at DATETIME NULL,
    INDEX idx_order_id (order_id),
    INDEX idx_phone_number (phone_number),
    INDEX idx_expires_at (expires_at)
)";

if ($conn->query($sql) === TRUE) {
    echo json_encode([
        'success' => true,
        'message' => 'Table completion_otp_storage created successfully'
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Error creating table: ' . $conn->error
    ]);
}

$conn->close();
?>
