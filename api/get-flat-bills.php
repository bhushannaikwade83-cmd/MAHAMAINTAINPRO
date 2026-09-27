<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Committee/secretary flat-wise view of all bills in the society - this
// exposes every resident's billing data, so it's manager-only, not just
// any member.
require_once 'jwt-auth.php';

$society_id = (int)($_GET['society_id'] ?? 0);
if ($society_id <= 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'society_id is required']);
    exit;
}

requireSocietyManagerRole($society_id);

try {
    $conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');
    if ($conn->connect_error) {
        throw new Exception('Database connection failed');
    }

    $conn->query("
        UPDATE society_maintenance_bills
        SET late_fee = ROUND(amount * 0.02 * GREATEST(FLOOR(DATEDIFF(CURDATE(), due_date) / 30), 0), 2)
        WHERE society_id = $society_id AND status = 'due' AND due_date IS NOT NULL AND due_date < CURDATE()
    ");

    $stmt = $conn->prepare("
        SELECT b.id, b.flat_id, f.flat_number, b.period_month, b.amount, b.late_fee,
               b.status, b.due_date, b.paid_at, b.created_at
        FROM society_maintenance_bills b
        JOIN society_flats f ON f.id = b.flat_id
        WHERE b.society_id = ?
        ORDER BY f.flat_number ASC, b.period_month DESC
    ");
    $stmt->bind_param('i', $society_id);
    $stmt->execute();
    $result = $stmt->get_result();

    $bills = [];
    $totalOutstanding = 0;
    while ($row = $result->fetch_assoc()) {
        $row['total_due'] = (float)$row['amount'] + (float)$row['late_fee'];
        if ($row['status'] === 'due') $totalOutstanding += $row['total_due'];
        $bills[] = $row;
    }

    echo json_encode([
        'success' => true,
        'bills' => $bills,
        'total' => count($bills),
        'total_outstanding' => $totalOutstanding,
    ]);
    $stmt->close();
    $conn->close();
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
