<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
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
    $data = json_decode(file_get_contents('php://input'), true);

    $phoneNumber = $data['phone_number'] ?? null;
    $addressType = $data['address_type'] ?? 'Home';
    $building = $data['building'] ?? '';
    $buildingName = $data['building_name'] ?? '';
    $street = $data['street'] ?? '';
    $pincode = $data['pincode'] ?? '';
    $area = $data['area'] ?? '';
    $latitude = $data['latitude'] ?? 0;
    $longitude = $data['longitude'] ?? 0;
    $label = $data['label'] ?? '';
    $deliveryInstructions = $data['delivery_instructions'] ?? '';
    $fullAddress = $data['full_address'] ?? '';

    if (!$phoneNumber) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Missing phone number']);
        exit();
    }

    // Insert new address
    $insertStmt = $conn->prepare("
        INSERT INTO addresses
        (phone_number, address_type, building, building_name, street, pincode, area, latitude, longitude, label, delivery_instructions, full_address, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
    ");

    $insertStmt->bind_param(
        "sssssssddsss",
        $phoneNumber, $addressType, $building, $buildingName, $street, $pincode, $area,
        $latitude, $longitude, $label, $deliveryInstructions, $fullAddress
    );

    if ($insertStmt->execute()) {
        $addressId = $insertStmt->insert_id;
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Address saved successfully',
            'address_id' => $addressId,
        ]);
    } else {
        throw new Exception("Insert failed: " . $insertStmt->error);
    }

    $insertStmt->close();
} catch (Exception $e) {
    http_response_code(500);
    error_log($e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
