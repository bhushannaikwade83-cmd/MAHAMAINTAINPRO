<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

// Single service_requests row by id, for whichever party actually owns
// it - the customer who placed it, or the vendor assigned to it. This is
// what the customer's live tracking screen needs (by request_id); the
// existing vendor-get-requests.php only supports listing by vendor_id, so
// this fills that gap rather than forcing a mismatched param onto it.
require_once __DIR__ . '/../jwt-auth.php';
$authToken = verifyJWTToken();

try {
    $pdo = new PDO("mysql:host=localhost;dbname=digitrix_maha_maintain_pro;charset=utf8mb4",
        "digitrix_maha_user", "maha_user@70", [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);

    $request_id = $_GET['request_id'] ?? null;
    if (!$request_id) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'request_id required']);
        exit;
    }

    $stmt = $pdo->prepare("
        SELECT sr.*, s.name as service_name, sc.name as category_name
        FROM service_requests sr
        JOIN services s ON sr.service_id = s.id
        JOIN service_categories sc ON sr.service_category_id = sc.id
        WHERE sr.id = ?
    ");
    $stmt->execute([$request_id]);
    $request = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$request) {
        http_response_code(404);
        echo json_encode(['success' => false, 'error' => 'Request not found']);
        exit;
    }

    $isCustomer = false;
    if ($request['customer_id']) {
        $custStmt = $pdo->prepare('SELECT id FROM individuals WHERE id = ? AND phone_number = ?');
        $custStmt->execute([$request['customer_id'], $authToken['phone_number']]);
        $isCustomer = (bool)$custStmt->fetch();
    }
    $isAssignedVendor = isset($authToken['vendor_id']) && $request['assigned_vendor_id'] && (string)$authToken['vendor_id'] === (string)$request['assigned_vendor_id'];

    if (!$isCustomer && !$isAssignedVendor) {
        http_response_code(403);
        echo json_encode(['success' => false, 'error' => 'You are not part of this service request']);
        exit;
    }

    echo json_encode(['success' => true, 'requests' => [$request]]);
} catch (Exception $e) {
    http_response_code(500);
    error_log('get-service-request error: ' . $e->getMessage());
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
