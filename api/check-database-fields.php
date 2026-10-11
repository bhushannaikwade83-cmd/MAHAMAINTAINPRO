<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);

if ($conn->connect_error) {
    echo json_encode(['error' => 'Connection failed']);
    exit();
}

try {
    // Get table structure
    $query = "DESCRIBE addresses";
    $result = $conn->query($query);

    $columns = [];
    while ($row = $result->fetch_assoc()) {
        $columns[] = $row;
    }

    // Get one sample record
    $query = "SELECT * FROM addresses ORDER BY id DESC LIMIT 1";
    $result = $conn->query($query);
    $sampleData = $result->fetch_assoc();

    echo json_encode([
        'success' => true,
        'table_columns' => $columns,
        'sample_data' => $sampleData,
        'column_names' => array_keys($sampleData)
    ], JSON_PRETTY_PRINT);

} catch (Exception $e) {
    echo json_encode(['error' => $e->getMessage()]);
}

$conn->close();
?>
