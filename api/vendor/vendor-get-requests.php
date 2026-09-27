<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

// vendor_id is taken from the vendor's own JWT, never trusted from the
// client - otherwise any vendor could list any other vendor's job queue.
require_once __DIR__ . '/../jwt-auth.php';
$authToken = requireVendorRole();
$vendor_id = $authToken['vendor_id'];

try {
    $pdo = new PDO("mysql:host=localhost;dbname=digitrix_maha_maintain_pro;charset=utf8mb4",
        "digitrix_maha_user", "maha_user@70", [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);

    $booking_type = $_GET['booking_type'] ?? null;
    $status = $_GET['status'] ?? null;

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
    error_log('vendor-get-requests error: ' . $e->getMessage());
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
