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
    $input = json_decode(file_get_contents('php://input'), true);

    $user_id = intval($input['user_id'] ?? 0);
    $is_committee = intval($input['is_committee'] ?? 0);
    $is_enabled = intval($input['is_enabled'] ?? 1);

    if ($user_id <= 0) {
        throw new Exception('User ID is required');
    }

    // Check if user already exists in society_customers_individual
    $checkStmt = $conn->prepare("SELECT id FROM society_customers_individual WHERE user_id = ?");
    $checkStmt->bind_param("i", $user_id);
    $checkStmt->execute();
    $checkResult = $checkStmt->get_result();

    if ($checkResult->num_rows > 0) {
        // User already exists - this is a duplicate registration attempt
        http_response_code(409);
        echo json_encode([
            'success' => false,
            'message' => 'User already registered in this society. Cannot register twice.',
            'action' => 'duplicate',
            'user_id' => $user_id
        ]);
    } else {
        // Insert new member
        $stmt = $conn->prepare("INSERT INTO society_customers_individual (user_id, is_committee, is_enabled) VALUES (?, ?, ?)");
        $stmt->bind_param("iii", $user_id, $is_committee, $is_enabled);
        $stmt->execute();

        http_response_code(201);
        echo json_encode([
            'success' => true,
            'message' => 'Member added successfully',
            'action' => 'created',
            'user_id' => $user_id,
            'is_committee' => (bool)$is_committee,
            'is_enabled' => (bool)$is_enabled
        ]);

        $stmt->close();
    }

    $checkStmt->close();

} catch (Exception $e) {
    http_response_code(400);
    error_log("Add member error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
