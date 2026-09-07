<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

try {
    $pdo = new PDO("mysql:host=localhost;dbname=digitrix_maha_maintain_pro;charset=utf8mb4",
        "digitrix_maha_user", "maha_user@70", [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);

    $vendor_id = $_GET['vendor_id'] ?? null;
    if (!$vendor_id) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'vendor_id required']);
        exit;
    }

    // Get vendor's pincodes and service categories
    $vendorStmt = $pdo->prepare("
        SELECT DISTINCT vsc.service_category_id FROM vendor_service_categories vsc
        WHERE vsc.vendor_id = ? AND vsc.is_active = 1
    ");
    $vendorStmt->execute([$vendor_id]);
    $categories = $vendorStmt->fetchAll(PDO::FETCH_COLUMN);

    if (empty($categories)) {
        echo json_encode(['success' => true, 'requests' => []]);
        exit;
    }

    // Get pending instant requests matching vendor's service categories
    $placeholders = implode(',', array_fill(0, count($categories), '?'));
    $stmt = $pdo->prepare("
        SELECT sr.*, s.name as service_name, sc.name as category_name
        FROM service_requests sr
        JOIN services s ON sr.service_id = s.id
        JOIN service_categories sc ON sr.service_category_id = sc.id
        WHERE sr.status = 'PENDING'
        AND sr.booking_type = 'INSTANT'
        AND sr.service_category_id IN ($placeholders)
        ORDER BY sr.created_at DESC
        LIMIT 20
    ");

    $params = array_merge($categories);
    $stmt->execute($params);
    $requests = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'requests' => $requests,
        'count' => count($requests)
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
