<?php
header('Content-Type: application/json');

$servername = "localhost";
$db_username = "root";
$db_password = "";
$database = "mahamaintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed: ' . $conn->connect_error]);
    exit();
}

// Read SQL file
$sql_file = __DIR__ . '/create_address_columns.sql';

if (!file_exists($sql_file)) {
    http_response_code(404);
    echo json_encode(['success' => false, 'message' => 'SQL file not found']);
    exit();
}

$sql = file_get_contents($sql_file);
$queries = array_filter(array_map('trim', preg_split('/;/', $sql)), function($q) {
    return !empty($q) && !str_starts_with($q, '--');
});

$executed = 0;
$errors = [];

foreach ($queries as $query) {
    if ($conn->query($query) === TRUE) {
        $executed++;
    } else {
        $errors[] = $conn->error;
    }
}

if (empty($errors)) {
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => "✅ Migration completed! Executed $executed queries",
        'queries_executed' => $executed
    ]);
} else {
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => "⚠️ Migration completed with warnings",
        'queries_executed' => $executed,
        'warnings' => $errors
    ]);
}

$conn->close();
?>
