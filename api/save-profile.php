<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Max-Age: 86400');

// Debug logging
$debug_file = '/home/digitrix/public_html/mahamaintainpro/api/debug.log';
function debug_log($message) {
    global $debug_file;
    $timestamp = date('Y-m-d H:i:s');
    file_put_contents($debug_file, "[$timestamp] $message\n", FILE_APPEND);
}

debug_log("=== New Request ===");
debug_log("Method: " . $_SERVER['REQUEST_METHOD']);

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
debug_log("Connecting to database: $dbname");
$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    debug_log("Database connection error: " . $conn->connect_error);
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Database connection failed: ' . $conn->connect_error]));
}

debug_log("Database connection successful");

$conn->set_charset("utf8");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $raw_input = file_get_contents("php://input");
    debug_log("Raw Input: " . $raw_input);

    $data = json_decode($raw_input, true);
    debug_log("Decoded Data: " . json_encode($data));

    if (!isset($data['phone_number']) || !isset($data['full_name'])) {
        debug_log("Error: Missing phone_number or full_name");
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Phone number and full name are required']));
    }

    debug_log("Phone: " . $data['phone_number'] . ", Name: " . $data['full_name']);

    $phone_number = $conn->real_escape_string(trim($data['phone_number']));
    $full_name = $conn->real_escape_string(trim($data['full_name']));
    $email = isset($data['email']) && !empty($data['email']) ? $conn->real_escape_string(trim($data['email'])) : NULL;
    $address = isset($data['address']) ? $conn->real_escape_string(trim($data['address'])) : '';
    $latitude = isset($data['latitude']) ? $conn->real_escape_string($data['latitude']) : '0';
    $longitude = isset($data['longitude']) ? $conn->real_escape_string($data['longitude']) : '0';

    // Validate phone number
    if (!preg_match('/^[0-9]{10}$/', $phone_number)) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Invalid phone number']));
    }

    // Check if individual exists
    $check_sql = "SELECT id FROM individuals WHERE phone = '$phone_number' LIMIT 1";
    debug_log("Check SQL: $check_sql");
    $check_result = $conn->query($check_sql);

    if (!$check_result) {
        debug_log("Check query error: " . $conn->error);
        http_response_code(500);
        die(json_encode(['success' => false, 'message' => 'Database query error: ' . $conn->error]));
    }

    debug_log("Check result rows: " . $check_result->num_rows);

    if ($check_result->num_rows > 0) {
        // Update existing profile
        debug_log("Updating existing profile");
        $email_update = $email ? ", email = '$email'" : '';
        $update_sql = "UPDATE individuals
                       SET full_name = '$full_name',
                           address = '$address',
                           latitude = '$latitude',
                           longitude = '$longitude'
                           $email_update,
                           updated_at = NOW()
                       WHERE phone = '$phone_number'";

        debug_log("Update SQL: $update_sql");

        if ($conn->query($update_sql)) {
            debug_log("Update successful");
            http_response_code(200);
            echo json_encode([
                'success' => true,
                'message' => 'Profile updated successfully',
                'phone_number' => $phone_number
            ]);
        } else {
            debug_log("Update error: " . $conn->error);
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Failed to update profile: ' . $conn->error]);
        }
    } else {
        // Create new individual profile
        debug_log("Creating new profile");
        $email_value = $email ? "'$email'" : 'NULL';
        $insert_sql = "INSERT INTO individuals
                       (phone, full_name, email, address, latitude, longitude, status, created_at)
                       VALUES ('$phone_number', '$full_name', $email_value, '$address', '$latitude', '$longitude', 'pending', NOW())";

        debug_log("Insert SQL: $insert_sql");

        if ($conn->query($insert_sql)) {
            debug_log("Insert successful");
            http_response_code(200);
            echo json_encode([
                'success' => true,
                'message' => 'Profile created successfully',
                'phone_number' => $phone_number
            ]);
        } else {
            debug_log("Insert error: " . $conn->error);
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Failed to create profile: ' . $conn->error]);
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
