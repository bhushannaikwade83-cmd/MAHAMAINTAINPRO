<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
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
    $phoneNumber = $_GET['phone_number'] ?? null;

    if (!$phoneNumber) {
        throw new Exception('phone_number parameter required');
    }

    // Check if individual exists - use correct column names
    $query = "SELECT id, full_name, email, phone FROM individuals WHERE phone = ?";
    $stmt = $conn->prepare($query);
    if (!$stmt) {
        throw new Exception('Prepare failed: ' . $conn->error);
    }
    $stmt->bind_param('s', $phoneNumber);
    $stmt->execute();
    $result = $stmt->get_result();
    $stmt->close();

    if ($result->num_rows > 0) {
        $individual = $result->fetch_assoc();
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'exists' => true,
            'phone_number' => $phoneNumber,
            'full_name' => $individual['full_name'] ?? $individual['name'] ?? '',
            'email' => $individual['email'],
        ]);
    } else {
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'exists' => false,
            'phone_number' => $phoneNumber,
            'message' => 'Individual does not exist - needs profile creation',
        ]);
    }

} catch (Exception $e) {
    http_response_code(400);
    error_log("Check individual error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'An internal error occurred. Please try again.']);
}

$conn->close();
?>
