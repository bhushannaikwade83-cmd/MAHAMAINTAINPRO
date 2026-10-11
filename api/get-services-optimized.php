<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Cache-Control: public, max-age=3600'); // 1 hour cache

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
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit();
}

try {
    // Optimized query - select only needed columns
    $query = "SELECT
        id,
        name,
        category,
        image_path,
        rating,
        description,
        price_range
    FROM services
    WHERE status = 'active'
    ORDER BY rating DESC, name ASC
    LIMIT 100";

    $result = $conn->query($query);

    if (!$result) {
        throw new Exception('Query failed: ' . $conn->error);
    }

    $services = [];
    while ($row = $result->fetch_assoc()) {
        $services[] = $row;
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'count' => count($services),
        'data' => $services,
        'cached' => true
    ]);

} catch (Exception $e) {
    http_response_code(400);
    error_log("Get services error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
