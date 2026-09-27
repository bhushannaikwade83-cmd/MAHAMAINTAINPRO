<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// JWT Authentication (Security Layer)
require_once 'jwt-auth.php';
$token = verifyJWTToken();
$phone_number = $token['phone_number'];

// Database connection
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
    // Fetch this user's addresses only (phone_number comes from verified JWT)
    $query = "SELECT id, address_type, full_address, building, building_name, street,
              pincode, area, latitude, longitude,
              label, delivery_instructions, created_at
              FROM addresses WHERE phone_number = ? ORDER BY created_at DESC LIMIT 10";

    $stmt = $conn->prepare($query);
    $stmt->bind_param("s", $phone_number);
    $stmt->execute();
    $result = $stmt->get_result();

    $addresses = [];
    while ($row = $result->fetch_assoc()) {
        $addresses[] = $row;
    }

    $stmt->close();

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'addresses' => $addresses,
        'count' => count($addresses)
    ]);

} catch (Exception $e) {
    http_response_code(500);
    error_log("Address fetch error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'An internal error occurred. Please try again.']);
}

$conn->close();
?>
