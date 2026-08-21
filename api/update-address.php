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

    $addressId = $data['address_id'] ?? null;
    $phoneNumber = $data['phone_number'] ?? null;
    $addressType = $data['address_type'] ?? 'Home';
    $building = $data['building'] ?? '';
    $buildingName = $data['building_name'] ?? '';
    $street = $data['street'] ?? '';
    $pincode = $data['pincode'] ?? '';
    $area = $data['area'] ?? '';
    $city = $data['city'] ?? '';
    $taluka = $data['taluka'] ?? '';
    $district = $data['district'] ?? '';
    $state = $data['state'] ?? '';
    $latitude = $data['latitude'] ?? 0;
    $longitude = $data['longitude'] ?? 0;
    $label = $data['label'] ?? '';
    $deliveryInstructions = $data['delivery_instructions'] ?? '';
    $fullAddress = $data['full_address'] ?? '';

    if (!$addressId || !$phoneNumber) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Missing required fields']);
        exit();
    }

    // Update address in database
    $updateStmt = $conn->prepare("
        UPDATE addresses
        SET address_type = ?, building = ?, building_name = ?, street = ?,
            pincode = ?, area = ?, city = ?, taluka = ?, district = ?, state = ?,
            latitude = ?, longitude = ?, label = ?, delivery_instructions = ?,
            full_address = ?, updated_at = NOW()
        WHERE id = ? AND phone_number = ?
    ");

    $updateStmt->bind_param(
        "ssssssssssddssi",
        $addressType, $building, $buildingName, $street, $pincode,
        $area, $city, $taluka, $district, $state,
        $latitude, $longitude, $label, $deliveryInstructions, $fullAddress,
        $addressId, $phoneNumber
    );

    if ($updateStmt->execute()) {
        if ($updateStmt->affected_rows > 0) {
            http_response_code(200);
            echo json_encode([
                'success' => true,
                'message' => 'Address updated successfully',
                'address_id' => $addressId,
            ]);
        } else {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Address not found or no changes made']);
        }
    } else {
        throw new Exception("Update failed: " . $updateStmt->error);
    }

    $updateStmt->close();
} catch (Exception $e) {
    http_response_code(500);
    error_log($e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
