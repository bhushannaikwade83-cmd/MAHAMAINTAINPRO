<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'jwt-auth.php';

$data = json_decode(file_get_contents('php://input'), true);

if (!$data || !isset($data['id']) || !isset($data['society_id']) || !isset($data['status'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'id, society_id and status are required']);
    exit;
}

$society_id = (int)$data['society_id'];
requireSocietyManagerRole($society_id);

$id = (int)$data['id'];
$status = $data['status'];

if (!in_array($status, ['open', 'in_progress', 'resolved'], true)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Invalid status']);
    exit;
}

try {
    $pdo = new PDO(
        "mysql:host=localhost;dbname=digitrix_maha_maintain_pro;charset=utf8mb4",
        "digitrix_maha_user",
        "maha_user@70",
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    if ($status === 'resolved') {
        $resolution_remarks = isset($data['resolution_remarks']) ? trim($data['resolution_remarks']) : null;
        $resolution_photo_url = isset($data['resolution_photo_url']) && $data['resolution_photo_url'] !== '' ? trim($data['resolution_photo_url']) : null;
        $stmt = $pdo->prepare('
            UPDATE society_complaints
            SET status = ?, resolution_remarks = ?, resolution_photo_url = ?, customer_confirmed = 0, resolved_at = NOW(), updated_at = NOW()
            WHERE id = ? AND society_id = ?
        ');
        $stmt->execute([$status, $resolution_remarks, $resolution_photo_url, $id, $society_id]);
    } else {
        $stmt = $pdo->prepare('UPDATE society_complaints SET status = ?, updated_at = NOW() WHERE id = ? AND society_id = ?');
        $stmt->execute([$status, $id, $society_id]);
    }

    if ($stmt->rowCount() === 0) {
        http_response_code(404);
        echo json_encode(['success' => false, 'error' => 'Complaint not found']);
        exit;
    }

    // Push the update to the resident who raised it.
    require_once 'push-notification-helper.php';
    $phoneStmt = $pdo->prepare('
        SELECT i.phone_number, c.category FROM society_complaints c
        JOIN individuals i ON i.id = c.user_id
        WHERE c.id = ?
    ');
    $phoneStmt->execute([$id]);
    $complaintRow = $phoneStmt->fetch(PDO::FETCH_ASSOC);
    if ($complaintRow) {
        $statusLabel = str_replace('_', ' ', $status);
        $mysqliConn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');
        if (!$mysqliConn->connect_error) {
            sendPushToPhone(
                $mysqliConn,
                $complaintRow['phone_number'],
                'Complaint update',
                "Your complaint ({$complaintRow['category']}) is now: " . ucfirst($statusLabel),
                ['type' => 'complaint', 'complaint_id' => (string)$id]
            );
            $mysqliConn->close();
        }
    }

    echo json_encode(['success' => true, 'message' => 'Complaint status updated successfully']);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
