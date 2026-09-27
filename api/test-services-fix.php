<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
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
    echo json_encode([
        'success' => false,
        'error' => 'Database connection failed: ' . $conn->connect_error
    ]);
    exit();
}

try {
    // Simple test - just get categories
    $categories = [];

    // Get column names from service_categories
    $columnsResult = $conn->query("DESCRIBE service_categories");
    $columns = [];
    if ($columnsResult) {
        while ($col = $columnsResult->fetch_assoc()) {
            $columns[] = $col['Field'];
        }
    }

    // Build safe query using only available columns
    $safeColumns = ['id', 'name', 'description'];
    $selectCols = implode(", ", $safeColumns);

    $query = "SELECT {$selectCols} FROM service_categories WHERE is_active = 1 ORDER BY id ASC";
    $result = $conn->query($query);

    if (!$result) {
        throw new Exception("Query failed: " . $conn->error);
    }

    while ($row = $result->fetch_assoc()) {
        $categoryId = $row['id'];

        // Get services for this category
        $serviceQuery = "SELECT id, name, price, duration FROM services WHERE category_id = ? AND is_active = 1 ORDER BY id ASC";
        $stmt = $conn->prepare($serviceQuery);

        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }

        $stmt->bind_param("i", $categoryId);
        $stmt->execute();
        $serviceResult = $stmt->get_result();

        $services = [];
        while ($serviceRow = $serviceResult->fetch_assoc()) {
            $services[] = $serviceRow;
        }
        $stmt->close();

        $categories[] = [
            'id' => $row['id'],
            'name' => $row['name'],
            'description' => $row['description'],
            'services' => $services,
            'service_count' => count($services),
        ];
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'categories' => $categories,
        'total_categories' => count($categories),
        'database_columns' => $columns,
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'An internal error occurred. Please try again.'
    ]);
}

$conn->close();
?>
