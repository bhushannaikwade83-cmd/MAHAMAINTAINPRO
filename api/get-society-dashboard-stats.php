<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Read-only dashboard summary - restricted to members of THIS society only.
require_once 'jwt-auth.php';

$society_id = (int)($_GET['society_id'] ?? 0);

if ($society_id <= 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'society_id is required']);
    exit;
}

requireSocietyMembership($society_id);

try {
    $conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');
    if ($conn->connect_error) {
        throw new Exception('Database connection failed');
    }

    $stmt = $conn->prepare("
        SELECT
            COUNT(*) AS total_flats,
            SUM(occupancy_status = 'occupied') AS occupied,
            SUM(occupancy_status = 'vacant') AS vacant
        FROM society_flats
        WHERE society_id = ?
    ");
    $stmt->bind_param('i', $society_id);
    $stmt->execute();
    $flatStats = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    $stmt = $conn->prepare("
        SELECT
            COALESCE(SUM(amount), 0) AS maintenance_due,
            COUNT(*) AS due_bill_count
        FROM society_maintenance_bills
        WHERE society_id = ? AND status = 'due'
    ");
    $stmt->bind_param('i', $society_id);
    $stmt->execute();
    $dueStats = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    $currentMonth = date('Y-m');
    $stmt = $conn->prepare("
        SELECT COALESCE(SUM(amount), 0) AS collection_this_month
        FROM society_maintenance_bills
        WHERE society_id = ? AND status = 'paid' AND period_month = ?
    ");
    $stmt->bind_param('is', $society_id, $currentMonth);
    $stmt->execute();
    $collectionStats = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    $conn->close();

    echo json_encode([
        'success' => true,
        'stats' => [
            'total_flats' => (int)($flatStats['total_flats'] ?? 0),
            'occupied' => (int)($flatStats['occupied'] ?? 0),
            'vacant' => (int)($flatStats['vacant'] ?? 0),
            'maintenance_due' => (float)($dueStats['maintenance_due'] ?? 0),
            'due_bill_count' => (int)($dueStats['due_bill_count'] ?? 0),
            'collection_this_month' => (float)($collectionStats['collection_this_month'] ?? 0),
            'period_month' => $currentMonth,
        ],
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
