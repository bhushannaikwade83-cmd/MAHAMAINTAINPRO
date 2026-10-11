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

    $address_id = $data['address_id'] ?? null;
    $phone_number = $data['phone_number'] ?? null;

    if (!$address_id || !$phone_number) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Address ID and phone number are required']);
        exit();
    }

    // Verify user owns this address
    $check = $conn->prepare("SELECT id FROM addresses WHERE id = ? AND phone_number = ?");
    $check->bind_param("is", $address_id, $phone_number);
    $check->execute();
    $result = $check->get_result();

    if ($result->num_rows === 0) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Address not found']);
        exit();
    }

    // Delete address
    $delete = $conn->prepare("DELETE FROM addresses WHERE id = ? AND phone_number = ?");
    $delete->bind_param("is", $address_id, $phone_number);

    if ($delete->execute()) {
        error_log("✅ Address deleted successfully - ID: $address_id");
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Address deleted successfully'
        ]);
    } else {
        error_log("❌ Delete failed: " . $delete->error);
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to delete address']);
    }

    $check->close();
    $delete->close();

} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}

$conn->close();
?>
