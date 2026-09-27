<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// user_id is derived from the JWT, never trusted from the client - a
// resident's bills across whichever flat(s) they're linked to as owner
// or tenant.
require_once 'jwt-auth.php';
$authToken = verifyJWTToken();

try {
    $conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');
    if ($conn->connect_error) {
        throw new Exception('Database connection failed');
    }

    $userStmt = $conn->prepare('SELECT id FROM individuals WHERE phone_number = ?');
    $userStmt->bind_param('s', $authToken['phone_number']);
    $userStmt->execute();
    $userRow = $userStmt->get_result()->fetch_assoc();
    $userStmt->close();
    if (!$userRow) {
        http_response_code(404);
        echo json_encode(['success' => false, 'error' => 'User account not found']);
        exit;
    }
    $user_id = (int)$userRow['id'];

    // Late fee: 2% of the bill amount per full month overdue, recomputed
    // and persisted on every read so it's always current before payment.
    $lateFeeStmt = $conn->prepare("
        UPDATE society_maintenance_bills b
        JOIN society_customers_individual m ON m.flat_id = b.flat_id AND m.user_id = ?
        SET b.late_fee = ROUND(b.amount * 0.02 * GREATEST(FLOOR(DATEDIFF(CURDATE(), b.due_date) / 30), 0), 2)
        WHERE b.status = 'due' AND b.due_date IS NOT NULL AND b.due_date < CURDATE()
    ");
    $lateFeeStmt->bind_param('i', $user_id);
    $lateFeeStmt->execute();
    $lateFeeStmt->close();

    $stmt = $conn->prepare("
        SELECT b.id, b.society_id, b.flat_id, f.flat_number, b.period_month, b.amount, b.late_fee,
               b.status, b.due_date, b.paid_at, b.payment_id, b.created_at
        FROM society_maintenance_bills b
        JOIN society_customers_individual m ON m.flat_id = b.flat_id AND m.user_id = ?
        JOIN society_flats f ON f.id = b.flat_id
        ORDER BY b.period_month DESC
    ");
    $stmt->bind_param('i', $user_id);
    $stmt->execute();
    $result = $stmt->get_result();

    $bills = [];
    while ($row = $result->fetch_assoc()) {
        $row['is_overdue'] = $row['status'] === 'due' && $row['due_date'] !== null && strtotime($row['due_date']) < time();
        $row['total_due'] = (float)$row['amount'] + (float)$row['late_fee'];
        $bills[] = $row;
    }

    echo json_encode(['success' => true, 'bills' => $bills, 'total' => count($bills)]);
    $stmt->close();
    $conn->close();
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
