<?php
/**
 * Marks an SOS alert as resolved, so it drops out of the security guard's
 * active-alerts feed. Previously sos_alerts had a status column but
 * nothing ever updated it away from 'active'.
 */
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'jwt-auth.php';
$authToken = verifyJWTToken();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    die(json_encode(['success' => false, 'message' => 'Method not allowed']));
}

try {
    require 'config.php';

    $data = json_decode(file_get_contents('php://input'), true);
    $alertId = isset($data['id']) ? (int) $data['id'] : 0;

    if ($alertId <= 0) {
        throw new Exception('id is required');
    }

    // Self-heal: these columns predate tracking who resolved an alert.
    $checkCol = $pdo->query("SHOW COLUMNS FROM sos_alerts LIKE 'resolved_by'");
    if ($checkCol->rowCount() === 0) {
        $pdo->exec("ALTER TABLE sos_alerts ADD COLUMN resolved_by VARCHAR(20) NULL, ADD COLUMN resolved_at DATETIME NULL");
    }

    $stmt = $pdo->prepare("UPDATE sos_alerts SET status = 'resolved', resolved_by = ?, resolved_at = NOW() WHERE id = ? AND status = 'active'");
    $stmt->execute([$authToken['phone_number'], $alertId]);

    if ($stmt->rowCount() === 0) {
        throw new Exception('Alert not found or already resolved');
    }

    echo json_encode(['success' => true, 'message' => 'Alert marked as resolved']);
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
