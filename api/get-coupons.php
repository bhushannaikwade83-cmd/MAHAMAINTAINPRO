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
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit();
}

try {
    // Create coupons table if not exists
    $createTable = "CREATE TABLE IF NOT EXISTS coupons (
        id INT AUTO_INCREMENT PRIMARY KEY,
        code VARCHAR(50) UNIQUE NOT NULL,
        description VARCHAR(255),
        discount_type ENUM('percentage', 'fixed') DEFAULT 'percentage',
        discount_value DECIMAL(10, 2) NOT NULL,
        min_amount DECIMAL(10, 2) DEFAULT 0,
        max_discount DECIMAL(10, 2),
        usage_limit INT,
        usage_count INT DEFAULT 0,
        is_active BOOLEAN DEFAULT 1,
        valid_from DATETIME,
        valid_until DATETIME,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )";

    if (!$conn->query($createTable)) {
        throw new Exception("Table creation failed: " . $conn->error);
    }

    // Fetch active coupons
    $query = "SELECT id, code, description, discount_type, discount_value, min_amount, max_discount
              FROM coupons
              WHERE is_active = 1
              AND (valid_until IS NULL OR valid_until > NOW())
              ORDER BY created_at DESC LIMIT 20";

    $result = $conn->query($query);

    if (!$result) {
        throw new Exception("Error fetching coupons: " . $conn->error);
    }

    $coupons = [];
    while ($row = $result->fetch_assoc()) {
        $coupons[] = $row;
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'coupons' => $coupons,
        'count' => count($coupons),
    ]);

} catch (Exception $e) {
    http_response_code(500);
    error_log("Coupon fetch error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
