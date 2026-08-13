<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Database credentials
$servername = "localhost";
$username = "maha_user";
$password = "YOUR_PASSWORD"; // Replace with actual password
$dbname = "maha_maintain_pro";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

// Set charset
$conn->set_charset("utf8");

// Handle POST request
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);

    // Validate individual data
    if (!isset($data['individual_name']) || !isset($data['individual_phone']) ||
        !isset($data['individual_email']) || !isset($data['individual_address']) ||
        !isset($data['society_name']) || !isset($data['society_address']) ||
        !isset($data['pincode']) || !isset($data['flat_number'])) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Missing required fields']));
    }

    // Sanitize input
    $individual_name = $conn->real_escape_string(trim($data['individual_name']));
    $individual_phone = $conn->real_escape_string(trim($data['individual_phone']));
    $individual_email = $conn->real_escape_string(trim($data['individual_email']));
    $individual_address = $conn->real_escape_string(trim($data['individual_address']));
    $society_name = $conn->real_escape_string(trim($data['society_name']));
    $society_address = $conn->real_escape_string(trim($data['society_address']));
    $pincode = $conn->real_escape_string(trim($data['pincode']));
    $flat_number = $conn->real_escape_string(trim($data['flat_number']));

    // Validate phone (10 digits)
    if (!preg_match('/^[0-9]{10}$/', $individual_phone)) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Invalid phone number']));
    }

    // Validate email
    if (!filter_var($individual_email, FILTER_VALIDATE_EMAIL)) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Invalid email address']));
    }

    // Validate pincode (6 digits)
    if (!preg_match('/^[0-9]{6}$/', $pincode)) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Invalid pincode']));
    }

    // Check if phone already exists
    $check_phone = $conn->query("SELECT id FROM individuals WHERE phone = '$individual_phone'");
    if ($check_phone->num_rows > 0) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Phone number already registered']));
    }

    // Check if email already exists
    $check_email = $conn->query("SELECT id FROM individuals WHERE email = '$individual_email'");
    if ($check_email->num_rows > 0) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Email already registered']));
    }

    // Start transaction
    $conn->begin_transaction();

    try {
        // Insert individual data
        $insert_individual = "INSERT INTO individuals
            (name, phone, email, address, status)
            VALUES ('$individual_name', '$individual_phone', '$individual_email', '$individual_address', 'pending')";

        if (!$conn->query($insert_individual)) {
            throw new Exception("Error inserting individual: " . $conn->error);
        }

        $individual_id = $conn->insert_id;

        // Insert society data
        $insert_society = "INSERT INTO societies
            (individual_id, society_name, society_address, pincode, flat_number, status)
            VALUES ($individual_id, '$society_name', '$society_address', '$pincode', '$flat_number', 'pending')";

        if (!$conn->query($insert_society)) {
            throw new Exception("Error inserting society: " . $conn->error);
        }

        // Commit transaction
        $conn->commit();

        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Registration submitted successfully. Awaiting admin approval.',
            'individual_id' => $individual_id
        ]);

    } catch (Exception $e) {
        // Rollback on error
        $conn->rollback();
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }

} else if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    // For testing
    http_response_code(200);
    echo json_encode(['success' => true, 'message' => 'API is working']);
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}

$conn->close();
?>
