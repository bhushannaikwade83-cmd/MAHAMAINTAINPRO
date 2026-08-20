<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

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

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);
    $phone_number = $data['phone_number'] ?? null;

    if (!$phone_number) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Phone number is required']);
        exit();
    }

    // Fetch all addresses for this user
    $query = "SELECT id, address_type, full_address, building, building_name, street,
              pincode, area, city, taluka, district, state, latitude, longitude,
              label, delivery_instructions, created_at
              FROM addresses WHERE phone_number = ? ORDER BY created_at DESC";

    $stmt = $conn->prepare($query);
    $stmt->bind_param("s", $phone_number);
    $stmt->execute();
    $result = $stmt->get_result();

    $addresses = [];
    while ($row = $result->fetch_assoc()) {
        $addresses[] = $row;
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'addresses' => $addresses,
        'count' => count($addresses)
    ]);

    $stmt->close();

} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}

$conn->close();
?>
