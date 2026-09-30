<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Database connection failed']);
    exit();
}

try {
    $query = "SELECT id, name, description, icon FROM service_categories ORDER BY name ASC";
    $result = $conn->query($query);

    if (!$result) {
        throw new Exception("Query failed: " . $conn->error);
    }

    $categories = [];
    while ($row = $result->fetch_assoc()) {
        $categories[] = [
            'id' => (int)$row['id'],
            'name' => $row['name'],
            'description' => $row['description'] ?? '',
            'icon' => $row['icon'] ?? ''
        ];
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'categories' => $categories,
        'count' => count($categories)
    ]);

} catch (Exception $e) {
    http_response_code(400);
    error_log("Categories list error: " . $e->getMessage());
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}

$conn->close();
?>
