<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// The resident who raised the complaint confirms the fix - user_id is
// derived from the JWT, never trusted from the client.
require_once 'jwt-auth.php';
$authToken = verifyJWTToken();

$data = json_decode(file_get_contents('php://input'), true);
$id = intval($data['id'] ?? 0);

if ($id <= 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'id is required']);
    exit;
}

try {
    $pdo = new PDO(
        "mysql:host=localhost;dbname=digitrix_maha_maintain_pro;charset=utf8mb4",
        "digitrix_maha_user",
        "maha_user@70",
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    $stmt = $pdo->prepare("
        UPDATE society_complaints c
        JOIN individuals i ON i.id = c.user_id
        SET c.customer_confirmed = 1, c.updated_at = NOW()
        WHERE c.id = ? AND i.phone_number = ? AND c.status = 'resolved'
    ");
    $stmt->execute([$id, $authToken['phone_number']]);

    if ($stmt->rowCount() === 0) {
        http_response_code(404);
        echo json_encode(['success' => false, 'error' => 'Complaint not found, not yours, or not yet resolved']);
        exit;
    }

    echo json_encode(['success' => true, 'message' => 'Resolution confirmed']);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
