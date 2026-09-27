<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Approves (or rejects) a refund request and, on approval, actually calls
// Razorpay's Refund API - the only place money moves backwards.
//
// Access: a home-service order isn't tied to any society, so only a true
// backend admin can approve its refund. A maintenance bill IS tied to a
// society, so its own secretary/committee (already trusted with billing -
// see requireSocietyManagerRole) can approve it too, without needing the
// separate admin panel.
require_once 'jwt-auth.php';
require_once 'razorpay-config.php';

$data = json_decode(file_get_contents('php://input'), true);
$type = $data['type'] ?? null;
$id = $data['id'] ?? null;
$approve = (bool)($data['approve'] ?? false);
$amount = isset($data['amount']) ? (float)$data['amount'] : null; // partial refund, optional

if (!in_array($type, ['order', 'bill'], true) || !$id) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'type (order/bill) and id are required']);
    exit;
}

$conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');

require_once 'ensure-orders-schema.php';
if (!$conn->connect_error) {
    ensureOrdersSchema($conn);
}
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit();
}

if ($type === 'order') {
    requireAdminRole();
} else {
    $billSocietyStmt = $conn->prepare('SELECT society_id FROM society_maintenance_bills WHERE id = ?');
    $billSocietyStmt->bind_param('i', $id);
    $billSocietyStmt->execute();
    $billSocietyRow = $billSocietyStmt->get_result()->fetch_assoc();
    $billSocietyStmt->close();

    if (!$billSocietyRow) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Bill not found']);
        exit;
    }
    requireSocietyManagerRole((int)$billSocietyRow['society_id']);
}

try {
    if ($type === 'order') {
        $stmt = $conn->prepare("SELECT payment_id, total_amount, refund_status FROM orders WHERE order_id = ?");
        $stmt->bind_param('s', $id);
    } else {
        $stmt = $conn->prepare("SELECT payment_id, (amount + late_fee) AS total_amount, refund_status FROM society_maintenance_bills WHERE id = ?");
        $stmt->bind_param('i', $id);
    }
    $stmt->execute();
    $record = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if (!$record) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Not found']);
        exit;
    }
    if ($record['refund_status'] !== 'requested') {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'No pending refund request for this ' . $type]);
        exit;
    }

    if (!$approve) {
        $table = $type === 'order' ? 'orders' : 'society_maintenance_bills';
        $idCol = $type === 'order' ? 'order_id' : 'id';
        $rejectStmt = $conn->prepare("UPDATE $table SET refund_status = 'rejected' WHERE $idCol = ?");
        $rejectStmt->bind_param($type === 'order' ? 's' : 'i', $id);
        $rejectStmt->execute();
        echo json_encode(['success' => true, 'message' => 'Refund request rejected']);
        exit;
    }

    if (empty($record['payment_id'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'No payment_id on record - cannot refund']);
        exit;
    }

    $refundAmount = $amount ?? (float)$record['total_amount'];

    if (RAZORPAY_KEY_SECRET === 'REPLACE_WITH_YOUR_RAZORPAY_KEY_SECRET') {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Server is not configured with a Razorpay key secret yet']);
        exit;
    }

    $ch = curl_init('https://api.razorpay.com/v1/payments/' . $record['payment_id'] . '/refund');
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => json_encode(['amount' => (int) round($refundAmount * 100)]),
        CURLOPT_USERPWD => RAZORPAY_KEY_ID . ':' . RAZORPAY_KEY_SECRET,
        CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
        CURLOPT_TIMEOUT => 20,
    ]);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);

    if ($response === false) {
        http_response_code(502);
        echo json_encode(['success' => false, 'message' => "Could not reach Razorpay: $curlError"]);
        exit;
    }

    $result = json_decode($response, true);
    if ($httpCode !== 200 || !isset($result['id'])) {
        http_response_code(502);
        echo json_encode(['success' => false, 'message' => $result['error']['description'] ?? 'Razorpay refund failed']);
        exit;
    }

    if ($type === 'order') {
        $updateStmt = $conn->prepare("
            UPDATE orders SET refund_status = 'processed', refund_id = ?, refunded_amount = ?, payment_status = 'refunded', order_status = 'refunded'
            WHERE order_id = ?
        ");
        $updateStmt->bind_param('sds', $result['id'], $refundAmount, $id);
    } else {
        $updateStmt = $conn->prepare("
            UPDATE society_maintenance_bills SET refund_status = 'processed', refund_id = ?, refunded_amount = ?, status = 'due'
            WHERE id = ?
        ");
        $updateStmt->bind_param('sdi', $result['id'], $refundAmount, $id);
    }
    $updateStmt->execute();

    $ledgerAdjustments = [];

    // A refunded order may have already paid a vendor for the job
    // (vendor_ledger JOB_EARNING row, credited when the vendor completed
    // it - see maha-vendor-app/server/update-job-status.php). Claw that
    // back with an equal, opposite ADJUSTMENT entry so the vendor's wallet
    // balance (SUM(amount) per vendor_id) reflects the refund. This writes
    // directly to the shared `bookings`/`vendor_ledger` tables rather than
    // calling into the vendor app, same as assign-complaint-vendor.php does.
    if ($type === 'order') {
        $bookingsStmt = $conn->prepare("SELECT id, vendor_id, amount FROM bookings WHERE order_id = ? AND vendor_id IS NOT NULL");
        $bookingsStmt->bind_param('s', $id);
        $bookingsStmt->execute();
        $bookings = $bookingsStmt->get_result()->fetch_all(MYSQLI_ASSOC);
        $bookingsStmt->close();

        foreach ($bookings as $booking) {
            $earningStmt = $conn->prepare("
                SELECT SUM(amount) AS total_earned FROM vendor_ledger
                WHERE booking_id = ? AND vendor_id = ? AND entry_type = 'JOB_EARNING'
            ");
            $earningStmt->bind_param('is', $booking['id'], $booking['vendor_id']);
            $earningStmt->execute();
            $earned = (float)($earningStmt->get_result()->fetch_assoc()['total_earned'] ?? 0);
            $earningStmt->close();

            if ($earned > 0) {
                $clawback = -$earned;
                $desc = "Refund clawback for order $id (booking {$booking['id']})";
                $insertLedger = $conn->prepare("
                    INSERT INTO vendor_ledger (vendor_id, booking_id, entry_type, amount, description)
                    VALUES (?, ?, 'ADJUSTMENT', ?, ?)
                ");
                $insertLedger->bind_param('sids', $booking['vendor_id'], $booking['id'], $clawback, $desc);
                $insertLedger->execute();
                $insertLedger->close();

                $ledgerAdjustments[] = ['vendor_id' => $booking['vendor_id'], 'booking_id' => $booking['id'], 'clawback' => $clawback];
            }
        }
    }

    echo json_encode([
        'success' => true,
        'message' => 'Refund processed successfully',
        'refund_id' => $result['id'],
        'vendor_ledger_adjustments' => $ledgerAdjustments,
        'refunded_amount' => $refundAmount,
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'An internal error occurred. Please try again.']);
}

$conn->close();
?>
