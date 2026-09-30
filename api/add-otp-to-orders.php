<?php
// Migration: Add OTP column to orders table

$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);

if ($conn->connect_error) {
    die(json_encode(['success' => false, 'error' => 'Connection failed: ' . $conn->connect_error]));
}

try {
    // Check if column exists
    $checkCol = $conn->query("SHOW COLUMNS FROM orders LIKE 'completion_otp'");

    if ($checkCol->num_rows === 0) {
        // Add completion_otp column (6-digit OTP)
        $sql = "ALTER TABLE orders ADD COLUMN completion_otp VARCHAR(6) NOT NULL DEFAULT ''";

        if ($conn->query($sql) === TRUE) {
            echo json_encode([
                'success' => true,
                'message' => 'Column completion_otp added to orders table'
            ]);
        } else {
            throw new Exception("Error adding column: " . $conn->error);
        }
    } else {
        echo json_encode([
            'success' => true,
            'message' => 'Column completion_otp already exists'
        ]);
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
