<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

try {
    $pdo = new PDO("mysql:host=localhost;dbname=digitrix_maha_maintain_pro;charset=utf8mb4",
        "digitrix_maha_user", "maha_user@70", [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);

    $vendor_id = $_GET['vendor_id'] ?? null;
    $booking_type = $_GET['booking_type'] ?? null;
    $status = $_GET['status'] ?? null;

    if (!$vendor_id) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'vendor_id required']);
        exit;
    }

    $query = "
        SELECT sr.*, s.name as service_name, sc.name as category_name
        FROM service_requests sr
        JOIN services s ON sr.service_id = s.id
        JOIN service_categories sc ON sr.service_category_id = sc.id
        WHERE sr.assigned_vendor_id = ?
    ";

    $params = [$vendor_id];

    if ($booking_type) {
        $query .= " AND sr.booking_type = ?";
        $params[] = $booking_type;
    }

    if ($status) {
        $query .= " AND sr.status = ?";
        $params[] = $status;
    }

    $query .= " ORDER BY sr.created_at DESC LIMIT 50";

    $stmt = $pdo->prepare($query);
    $stmt->execute($params);
    $requests = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'requests' => $requests,
        'total' => count($requests),
        'filters' => [
            'booking_type' => $booking_type,
            'status' => $status
        ]
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
