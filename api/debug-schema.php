<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);

if ($conn->connect_error) {
    echo json_encode(['error' => 'Connection failed: ' . $conn->connect_error]);
    exit();
}

try {
    // Check if individuals table exists
    $tableCheck = "SHOW TABLES LIKE 'individuals'";
    $result = $conn->query($tableCheck);
    $tableExists = $result->num_rows > 0;

    $output = [
        'database' => $database,
        'individuals_table_exists' => $tableExists,
        'columns' => [],
        'data_count' => 0,
        'errors' => []
    ];

    if ($tableExists) {
        // Get table structure
        $structureCheck = "DESCRIBE individuals";
        $result = $conn->query($structureCheck);
        while ($row = $result->fetch_assoc()) {
            $output['columns'][] = [
                'name' => $row['Field'],
                'type' => $row['Type'],
                'null' => $row['Null'],
                'key' => $row['Key'],
            ];
        }

        // Get row count
        $countCheck = "SELECT COUNT(*) as count FROM individuals";
        $result = $conn->query($countCheck);
        $row = $result->fetch_assoc();
        $output['data_count'] = $row['count'];

        // Get sample data (first 5 rows)
        $sampleCheck = "SELECT * FROM individuals LIMIT 5";
        $result = $conn->query($sampleCheck);
        $output['sample_data'] = [];
        while ($row = $result->fetch_assoc()) {
            $output['sample_data'][] = $row;
        }
    } else {
        $output['errors'][] = "Table 'individuals' does not exist";
    }

    http_response_code(200);
    echo json_encode($output, JSON_PRETTY_PRINT);

} catch (Exception $e) {
    echo json_encode(['error' => 'An internal error occurred. Please try again.']);
}

$conn->close();
?>
