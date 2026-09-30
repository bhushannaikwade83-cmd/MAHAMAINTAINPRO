<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

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
    $data = json_decode(file_get_contents('php://input'), true);

    $order_id = $data['order_id'] ?? null;
    $vendor_id = $data['vendor_id'] ?? null;
    $customer_phone = $data['customer_phone'] ?? null;
    $rating = $data['rating'] ?? null;
    $comment = $data['comment'] ?? null;

    if (!$order_id || !$vendor_id || !$customer_phone || !$rating) {
        throw new Exception('Missing required fields: order_id, vendor_id, customer_phone, rating');
    }

    if ($rating < 1 || $rating > 5) {
        throw new Exception('Rating must be between 1 and 5');
    }

    // Create ratings table if not exists
    $createTableSql = "CREATE TABLE IF NOT EXISTS ratings (
        id INT AUTO_INCREMENT PRIMARY KEY,
        order_id VARCHAR(50) NOT NULL,
        vendor_id INT NOT NULL,
        customer_phone VARCHAR(20) NOT NULL,
        rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
        comment TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY unique_order_rating (order_id),
        INDEX idx_vendor_id (vendor_id),
        INDEX idx_customer_phone (customer_phone),
        FOREIGN KEY (vendor_id) REFERENCES vendors(id) ON DELETE CASCADE
    )";
    $conn->query($createTableSql);

    // Insert or update rating
    $sql = "INSERT INTO ratings (order_id, vendor_id, customer_phone, rating, comment)
            VALUES (?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
            rating = ?, comment = ?, updated_at = NOW()";

    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }

    $stmt->bind_param('sisiiss', $order_id, $vendor_id, $customer_phone, $rating, $comment, $rating, $comment);

    if (!$stmt->execute()) {
        throw new Exception("Execute failed: " . $stmt->error);
    }

    $stmt->close();

    // Get updated vendor average rating
    $avgQuery = "SELECT ROUND(AVG(rating), 1) as avg_rating FROM ratings WHERE vendor_id = ?";
    $avgStmt = $conn->prepare($avgQuery);
    $avgStmt->bind_param('i', $vendor_id);
    $avgStmt->execute();
    $avgResult = $avgStmt->get_result();
    $avgRow = $avgResult->fetch_assoc();
    $avgRating = $avgRow['avg_rating'] ?? 0;
    $avgStmt->close();

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Rating saved successfully',
        'rating' => (int)$rating,
        'vendor_avg_rating' => (float)$avgRating,
    ]);

} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}

$conn->close();
?>
