<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Database connection failed',
        'details' => $conn->connect_error
    ]);
    exit();
}

$debug = [];

// Check if tables exist
$tables_to_check = ['service_categories', 'services'];
$debug['tables'] = [];

foreach ($tables_to_check as $table) {
    $result = $conn->query("SHOW TABLES LIKE '$table'");
    $exists = $result && $result->num_rows > 0;
    $debug['tables'][$table] = $exists;
}

// Try to get services
try {
    $result = $conn->query("SELECT COUNT(*) as count FROM service_categories");
    if ($result) {
        $row = $result->fetch_assoc();
        $debug['category_count'] = $row['count'];
    } else {
        $debug['category_error'] = $conn->error;
    }

    $result = $conn->query("SELECT COUNT(*) as count FROM services");
    if ($result) {
        $row = $result->fetch_assoc();
        $debug['service_count'] = $row['count'];
    } else {
        $debug['service_error'] = $conn->error;
    }

    // Get sample data
    $result = $conn->query("SELECT * FROM service_categories LIMIT 1");
    if ($result && $result->num_rows > 0) {
        $debug['sample_category'] = $result->fetch_assoc();
    } else if ($result) {
        $debug['sample_category'] = 'No categories found';
    } else {
        $debug['sample_category_error'] = $conn->error;
    }

} catch (Exception $e) {
    $debug['exception'] = $e->getMessage();
}

echo json_encode([
    'success' => true,
    'debug_info' => $debug
]);

$conn->close();
?>
