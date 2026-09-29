<?php
header('Content-Type: application/json');

$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);

if ($conn->connect_error) {
    die(json_encode(['success' => false, 'message' => 'Connection failed: ' . $conn->connect_error]));
}

try {
    // Ensure pincode column exists
    $checkCol = $conn->query("SHOW COLUMNS FROM orders LIKE 'pincode'");
    if ($checkCol->num_rows === 0) {
        $conn->query("ALTER TABLE orders ADD COLUMN pincode VARCHAR(10) NULL AFTER address_id");
        echo json_encode(['success' => true, 'message' => 'Added pincode column']);
    }

    // Update all existing orders with pincode from addresses table
    $updateQuery = "UPDATE orders o
                   JOIN addresses a ON o.address_id = a.id
                   SET o.pincode = a.pincode
                   WHERE o.pincode IS NULL";

    if ($conn->query($updateQuery)) {
        $affectedRows = $conn->affected_rows;
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => "Updated $affectedRows orders with pincode from addresses",
            'affected_rows' => $affectedRows
        ]);
    } else {
        throw new Exception("Update failed: " . $conn->error);
    }

} catch (Exception $e) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
