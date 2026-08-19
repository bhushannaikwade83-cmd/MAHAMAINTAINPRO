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
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit();
}

try {
    // Fetch all categories
    $query = "SELECT id, name, emoji, color, description, image_path FROM service_categories WHERE is_active = 1 ORDER BY id ASC";
    $result = $conn->query($query);

    if (!$result) {
        throw new Exception("Error fetching categories: " . $conn->error);
    }

    $categories = [];
    while ($row = $result->fetch_assoc()) {
        $categoryId = $row['id'];

        // Fetch services for this category
        $serviceQuery = "SELECT id, name, emoji, price, duration, rating, notes FROM services WHERE category_id = ? AND is_active = 1 ORDER BY id ASC";
        $stmt = $conn->prepare($serviceQuery);
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
            'emoji' => $row['emoji'],
            'color' => $row['color'],
            'description' => $row['description'],
            'image_path' => $row['image_path'],
            'services' => $services,
            'service_count' => count($services),
        ];
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'categories' => $categories,
        'total_categories' => count($categories),
    ]);

} catch (Exception $e) {
    http_response_code(500);
    error_log($e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
