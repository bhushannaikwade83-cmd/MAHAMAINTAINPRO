<?php
// Migration: Create ratings table

$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);

if ($conn->connect_error) {
    die(json_encode(['success' => false, 'error' => 'Connection failed: ' . $conn->connect_error]));
}

try {
    $sql = "CREATE TABLE IF NOT EXISTS ratings (
        id INT AUTO_INCREMENT PRIMARY KEY,
        order_id VARCHAR(50) NOT NULL,
        vendor_id INT NOT NULL,
        customer_phone VARCHAR(20) NOT NULL,
        rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
        comment TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY unique_order_rating (order_id),
        INDEX idx_vendor_id (vendor_id),
        INDEX idx_customer_phone (customer_phone),
        INDEX idx_rating (rating),
        INDEX idx_created_at (created_at),
        FOREIGN KEY (vendor_id) REFERENCES vendors(id) ON DELETE CASCADE
    )";

    if ($conn->query($sql) === TRUE) {
        echo json_encode([
            'success' => true,
            'message' => 'Ratings table created successfully'
        ]);
    } else {
        throw new Exception("Error creating table: " . $conn->error);
    }

} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}

$conn->close();
?>
