<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $pdo = new PDO("mysql:host=localhost;dbname=digitrix_maha_maintain_pro;charset=utf8mb4",
        "digitrix_maha_user", "maha_user@70", [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);

    $data = json_decode(file_get_contents('php://input'), true);

    if (!isset($data['request_id']) || !isset($data['vendor_id'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Missing: request_id, vendor_id']);
        exit;
    }

    $pdo->beginTransaction();

    // Get request details
    $reqStmt = $pdo->prepare("
        SELECT id, scheduled_date, status FROM service_requests
        WHERE id = ? AND booking_type = 'SLOT'
    ");
    $reqStmt->execute([$data['request_id']]);
    $request = $reqStmt->fetch(PDO::FETCH_ASSOC);

    if (!$request) {
        $pdo->rollBack();
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Slot request not found']);
        exit;
    }

    // Assign vendor
    $updateStmt = $pdo->prepare("
        UPDATE service_requests
        SET status = 'ASSIGNED',
            assigned_vendor_id = ?,
            accepted_at = NOW()
        WHERE id = ?
    ");
    $updateStmt->execute([$data['vendor_id'], $data['request_id']]);

    // Get vendor details
    $vendorStmt = $pdo->prepare("SELECT name, phone FROM vendors WHERE id = ?");
    $vendorStmt->execute([$data['vendor_id']]);
    $vendor = $vendorStmt->fetch(PDO::FETCH_ASSOC);

    // Update vendor details
    $detailStmt = $pdo->prepare("
        UPDATE service_requests
        SET vendor_name = ?, vendor_phone = ?
        WHERE id = ?
    ");
    $detailStmt->execute([$vendor['name'] ?? '', $vendor['phone'] ?? '', $data['request_id']]);

    $pdo->commit();

    echo json_encode([
        'success' => true,
        'request_id' => $data['request_id'],
        'vendor_id' => $data['vendor_id'],
        'status' => 'ASSIGNED',
        'scheduled_date' => $request['scheduled_date']
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
