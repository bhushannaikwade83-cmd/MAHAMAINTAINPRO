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

    // Validate required fields
    $phone_number = $data['phone_number'] ?? null;
    $address_type = $data['address_type'] ?? 'Home';
    $building = $data['building'] ?? '';
    $building_name = $data['building_name'] ?? '';
    $street = $data['street'] ?? '';
    $pincode = $data['pincode'] ?? '';
    $area = $data['area'] ?? '';
    $city = $data['city'] ?? '';
    $taluka = $data['taluka'] ?? '';
    $district = $data['district'] ?? '';
    $state = $data['state'] ?? '';
    $latitude = $data['latitude'] ?? null;
    $longitude = $data['longitude'] ?? null;
    $label = $data['label'] ?? '';
    $delivery_instructions = $data['delivery_instructions'] ?? '';
    $full_address = $data['full_address'] ?? '';

    if (!$phone_number || !$pincode) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Phone number and pincode are required']);
        exit();
    }

    // Check if user exists
    $check_user = $conn->prepare("SELECT phone FROM individuals WHERE phone = ?");
    $check_user->bind_param("s", $phone_number);
    $check_user->execute();
    $result = $check_user->get_result();

    if ($result->num_rows === 0) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'User not found']);
        exit();
    }

    // Insert address
    $insert_address = $conn->prepare("
        INSERT INTO addresses (
            phone_number, address_type, building, building_name, street,
            pincode, area, city, taluka, district, state,
            latitude, longitude, label, delivery_instructions, full_address
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ");

    $insert_address->bind_param(
        "ssssssssssssddss",
        $phone_number, $address_type, $building, $building_name, $street,
        $pincode, $area, $city, $taluka, $district, $state,
        $latitude, $longitude, $label, $delivery_instructions, $full_address
    );

    if ($insert_address->execute()) {
        error_log("✅ Address inserted successfully - ID: " . $insert_address->insert_id);

        // Also update individuals table with latest address (if column exists)
        $update_user = $conn->prepare("UPDATE individuals SET address = ? WHERE phone = ?");
        if ($update_user) {
            $update_user->bind_param("ss", $full_address, $phone_number);
            $update_user->execute();
            error_log("✅ Address updated in individuals table");
            $update_user->close();
        }

        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Address saved successfully',
            'address_id' => $insert_address->insert_id
        ]);
    } else {
        http_response_code(500);
        error_log("❌ Insert failed: " . $insert_address->error);
        echo json_encode([
            'success' => false,
            'message' => 'Failed to save address: ' . $insert_address->error
        ]);
    }

    $check_user->close();
    $insert_address->close();

} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}

$conn->close();
?>
