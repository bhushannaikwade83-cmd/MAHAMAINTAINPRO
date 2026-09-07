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

    // Update request status to ASSIGNED
    $stmt = $pdo->prepare("
        UPDATE service_requests
        SET status = 'ASSIGNED',
            assigned_vendor_id = ?,
            accepted_at = NOW()
        WHERE id = ? AND status = 'PENDING'
    ");
    $stmt->execute([$data['vendor_id'], $data['request_id']]);

    if ($stmt->rowCount() === 0) {
        $pdo->rollBack();
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Request not found or already assigned']);
        exit;
    }

    // Get vendor details
    $vendorStmt = $pdo->prepare("SELECT name, phone FROM vendors WHERE id = ?");
    $vendorStmt->execute([$data['vendor_id']]);
    $vendor = $vendorStmt->fetch(PDO::FETCH_ASSOC);

    // Update vendor details in request
    $updateStmt = $pdo->prepare("
        UPDATE service_requests
        SET vendor_name = ?, vendor_phone = ?
        WHERE id = ?
    ");
    $updateStmt->execute([$vendor['name'] ?? '', $vendor['phone'] ?? '', $data['request_id']]);

    $pdo->commit();

    echo json_encode([
        'success' => true,
        'request_id' => $data['request_id'],
        'status' => 'ASSIGNED',
        'vendor_id' => $data['vendor_id'],
        'estimated_arrival' => $data['estimated_time'] ?? '15 mins'
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
