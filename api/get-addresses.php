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

try {
    $phone_number = null;

    // Get phone number from POST or GET
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $data = json_decode(file_get_contents("php://input"), true);
        $phone_number = $data['phone_number'] ?? null;
    } elseif ($_SERVER['REQUEST_METHOD'] === 'GET') {
        $phone_number = $_GET['phone_number'] ?? null;
    }

    // If phone_number provided, fetch specific user's addresses
    if ($phone_number) {
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
    } else {
        // If no phone number, fetch latest addresses (for testing)
        $query = "SELECT id, address_type, full_address, building, building_name, street,
                  pincode, area, latitude, longitude,
                  label, delivery_instructions, created_at
                  FROM addresses ORDER BY created_at DESC LIMIT 10";

        $result = $conn->query($query);
        $addresses = [];
        while ($row = $result->fetch_assoc()) {
            $addresses[] = $row;
        }
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'addresses' => $addresses,
        'count' => count($addresses)
    ]);

} catch (Exception $e) {
    http_response_code(500);
    error_log("Address fetch error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
