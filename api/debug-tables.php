<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);

if ($conn->connect_error) {
    die(json_encode(['error' => $conn->connect_error]));
}

$vendor_id = 4;

// Check vendor_pincodes table
$pincodes = [];
$result = $conn->query("SELECT * FROM vendor_pincodes WHERE vendor_id = $vendor_id");
if ($result) {
    while ($row = $result->fetch_assoc()) {
        $pincodes[] = $row;
    }
}

// Check vendor_service_categories table
$categories = [];
$result = $conn->query("SELECT * FROM vendor_service_categories WHERE vendor_id = $vendor_id");
if ($result) {
    while ($row = $result->fetch_assoc()) {
        $categories[] = $row;
    }
}

// Check addresses table columns
$addressCols = [];
$result = $conn->query("DESCRIBE addresses");
if ($result) {
    while ($row = $result->fetch_assoc()) {
        $addressCols[] = $row['Field'];
    }
}

// Check order_items table columns
$orderItemsCols = [];
$result = $conn->query("DESCRIBE order_items");
if ($result) {
    while ($row = $result->fetch_assoc()) {
        $orderItemsCols[] = $row['Field'];
    }
}

echo json_encode([
    'vendor_id' => $vendor_id,
    'vendor_pincodes' => $pincodes,
    'vendor_categories' => $categories,
    'addresses_columns' => $addressCols,
    'order_items_columns' => $orderItemsCols
], JSON_PRETTY_PRINT);

$conn->close();
?>
