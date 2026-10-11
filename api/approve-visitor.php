<?php
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    header('Content-Type: application/json');
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: POST, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization');
    header('Access-Control-Max-Age: 86400');
    http_response_code(200);
    exit();
}

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

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
    $visitor_id = $input['visitor_id'] ?? null;
    $status = $input['status'] ?? 'approved';

    if (!$visitor_id) {
        throw new Exception('Missing visitor_id');
    }

    // Validate status
    $validStatuses = ['pending', 'approved', 'denied'];
    if (!in_array($status, $validStatuses)) {
        throw new Exception('Invalid status. Must be: ' . implode(', ', $validStatuses));
    }

    // Update visitor status
    $query = "UPDATE visitors SET status = ?, updated_at = NOW() WHERE id = ?";
    $stmt = $conn->prepare($query);
    if (!$stmt) throw new Exception('Prepare failed: ' . $conn->error);

    $stmt->bind_param('si', $status, $visitor_id);

    if (!$stmt->execute()) {
        throw new Exception('Update failed: ' . $stmt->error);
    }

    $affected = $stmt->affected_rows;
    $stmt->close();

    if ($affected > 0) {
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Visitor status updated to: ' . $status,
            'visitor_id' => $visitor_id,
            'status' => $status
        ]);
    } else {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Visitor not found'
        ]);
    }

} catch (Exception $e) {
    http_response_code(400);
    error_log("Approve visitor error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
