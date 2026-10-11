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
    $toggle_field = trim($input['toggle_field'] ?? '');
    $value = intval($input['value'] ?? 0);

    if ($user_id <= 0) {
        throw new Exception('User ID is required');
    }

    if (!in_array($toggle_field, ['is_enabled', 'is_committee'])) {
        throw new Exception('Invalid toggle field. Must be is_enabled or is_committee');
    }

    // Update the specified field
    $updateQuery = "UPDATE society_customers_individual SET $toggle_field = ?, updated_at = CURRENT_TIMESTAMP WHERE user_id = ?";
    $stmt = $conn->prepare($updateQuery);
    $stmt->bind_param("ii", $value, $user_id);
    $stmt->execute();

    if ($stmt->affected_rows === 0) {
        throw new Exception('Member not found');
    }

    // Fetch updated member data
    $fetchStmt = $conn->prepare("SELECT user_id, is_committee, is_enabled, updated_at FROM society_customers_individual WHERE user_id = ?");
    $fetchStmt->bind_param("i", $user_id);
    $fetchStmt->execute();
    $result = $fetchStmt->get_result();
    $member = $result->fetch_assoc();

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => ucfirst(str_replace('_', ' ', $toggle_field)) . ' updated successfully',
        'field' => $toggle_field,
        'member' => $member
    ]);

    $stmt->close();
    $fetchStmt->close();

} catch (Exception $e) {
    http_response_code(400);
    error_log("Toggle member error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
