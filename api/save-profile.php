<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Max-Age: 86400');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Database credentials
$servername = "localhost";
$username = "digitrix_maha_user";
$password = "maha_user@70";
$dbname = "digitrix_maha_maintain_pro";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

$conn->set_charset("utf8");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);

    if (!isset($data['phone_number']) || !isset($data['full_name'])) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Phone number and full name are required']));
    }

    $phone_number = $conn->real_escape_string(trim($data['phone_number']));
    $full_name = $conn->real_escape_string(trim($data['full_name']));
    $address = isset($data['address']) ? $conn->real_escape_string(trim($data['address'])) : '';
    $latitude = isset($data['latitude']) ? $conn->real_escape_string($data['latitude']) : '0';
    $longitude = isset($data['longitude']) ? $conn->real_escape_string($data['longitude']) : '0';

    // Validate phone number
    if (!preg_match('/^[0-9]{10}$/', $phone_number)) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Invalid phone number']));
    }

    // Check if individual exists
    $check_sql = "SELECT id FROM individuals WHERE phone_number = '$phone_number' LIMIT 1";
    $check_result = $conn->query($check_sql);

    if ($check_result->num_rows > 0) {
        // Update existing profile
        $update_sql = "UPDATE individuals
                       SET full_name = '$full_name',
                           address = '$address',
                           latitude = '$latitude',
                           longitude = '$longitude',
                           updated_at = NOW()
                       WHERE phone_number = '$phone_number'";

        if ($conn->query($update_sql)) {
            http_response_code(200);
            echo json_encode([
                'success' => true,
                'message' => 'Profile updated successfully',
                'phone_number' => $phone_number
            ]);
        } else {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Failed to update profile']);
        }
    } else {
        // Create new individual profile
        $insert_sql = "INSERT INTO individuals
                       (phone_number, full_name, address, latitude, longitude, status, created_at)
                       VALUES ('$phone_number', '$full_name', '$address', '$latitude', '$longitude', 'pending', NOW())";

        if ($conn->query($insert_sql)) {
            http_response_code(200);
            echo json_encode([
                'success' => true,
                'message' => 'Profile created successfully',
                'phone_number' => $phone_number
            ]);
        } else {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Failed to create profile']);
        }
    }

} else if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    http_response_code(200);
    echo json_encode(['success' => true, 'message' => 'Save Profile API is working']);
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}

$conn->close();
?>
