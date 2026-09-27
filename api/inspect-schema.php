<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// Admin-only: this dumps table schemas and row counts - a debugging aid,
// not something that should ever be reachable by an unauthenticated caller.
require_once 'jwt-auth.php';
requireAdminRole();

$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);

if ($conn->connect_error) {
    echo json_encode(['error' => 'Connection failed: ' . $conn->connect_error]);
    exit();
}

// Get table structure
$tables = ['service_categories', 'services', 'society_customers_individual'];
$schema = [];

foreach ($tables as $table) {
    $result = $conn->query("DESCRIBE $table");
    if ($result) {
        $columns = [];
        while ($row = $result->fetch_assoc()) {
            $columns[] = [
                'name' => $row['Field'],
                'type' => $row['Type'],
                'null' => $row['Null'],
                'key' => $row['Key'],
                'default' => $row['Default'],
            ];
        }
        $schema[$table] = $columns;
    } else {
        $schema[$table] = ['error' => $conn->error];
    }
}

// Get row counts
$counts = [];
foreach ($tables as $table) {
    $result = $conn->query("SELECT COUNT(*) as count FROM $table");
    if ($result) {
        $row = $result->fetch_assoc();
        $counts[$table] = $row['count'];
    }
}

echo json_encode([
    'success' => true,
    'schema' => $schema,
    'row_counts' => $counts,
]);

$conn->close();
?>
