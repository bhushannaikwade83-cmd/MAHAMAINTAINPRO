<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Max-Age: 86400');

// Handle CORS preflight request
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

    // Validate email
    if (!isset($data['email']) || empty($data['email'])) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Email is required']));
    }

    $email = $conn->real_escape_string(trim($data['email']));

    // Validate email format
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Invalid email address']));
    }

    // Check if individual exists
    $sql = "SELECT id, name, email, phone, status FROM individuals WHERE email = '$email'";
    $result = $conn->query($sql);

    if ($result->num_rows == 0) {
        http_response_code(401);
        die(json_encode([
            'success' => false,
            'message' => 'Email not registered. Please sign up first.',
            'action' => 'signup'
        ]));
    }

    $individual = $result->fetch_assoc();
    $individual_id = $individual['id'];
    $status = $individual['status'];

    // Check registration status
    if ($status === 'pending') {
        http_response_code(403);
        die(json_encode([
            'success' => false,
            'message' => 'Your registration is pending admin approval. You will receive email confirmation.',
            'action' => 'pending',
            'individual_id' => $individual_id
        ]));
    }

    if ($status === 'rejected') {
        http_response_code(403);
        die(json_encode([
            'success' => false,
            'message' => 'Your registration was rejected. Please contact support.',
            'action' => 'rejected'
        ]));
    }

    if ($status !== 'approved') {
        http_response_code(403);
        die(json_encode([
            'success' => false,
            'message' => 'Invalid registration status',
            'action' => 'error'
        ]));
    }

    // Get society info
    $society_sql = "SELECT id, society_name, pincode FROM societies WHERE individual_id = $individual_id LIMIT 1";
    $society_result = $conn->query($society_sql);
    $society = $society_result->fetch_assoc();

    // Login successful
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Login successful',
        'individual' => [
            'id' => $individual['id'],
            'name' => $individual['name'],
            'email' => $individual['email'],
            'phone' => $individual['phone'],
            'status' => $individual['status']
        ],
        'society' => $society,
        'userRole' => 'individual'
    ]);

} else if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    // For testing
    http_response_code(200);
    echo json_encode(['success' => true, 'message' => 'Login API is working']);
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}

$conn->close();
?>
