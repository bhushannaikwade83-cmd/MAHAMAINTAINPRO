<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Admin-only: adds the columns needed for (1) server-verified coupon
// discounts on orders and (2) refund tracking on both orders and
// maintenance bills.
require_once 'jwt-auth.php';
requireAdminRole();

$conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit();
}

$applied = [];
$skipped = [];

function run($conn, $label, $sql, &$applied, &$skipped) {
    if ($conn->query($sql)) {
        $applied[] = $label;
    } else {
        $skipped[] = "$label ({$conn->error})";
    }
}

run($conn, 'orders.coupon_code', "ALTER TABLE orders ADD COLUMN coupon_code VARCHAR(50) NULL", $applied, $skipped);
run($conn, 'orders.discount_amount', "ALTER TABLE orders ADD COLUMN discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0", $applied, $skipped);
run($conn, 'orders.refund_status', "ALTER TABLE orders ADD COLUMN refund_status ENUM('none', 'requested', 'processed', 'rejected') NOT NULL DEFAULT 'none'", $applied, $skipped);
run($conn, 'orders.refund_reason', "ALTER TABLE orders ADD COLUMN refund_reason TEXT NULL", $applied, $skipped);
run($conn, 'orders.refund_id', "ALTER TABLE orders ADD COLUMN refund_id VARCHAR(100) NULL", $applied, $skipped);
run($conn, 'orders.refunded_amount', "ALTER TABLE orders ADD COLUMN refunded_amount DECIMAL(10,2) NULL", $applied, $skipped);
run($conn, 'orders.razorpay_order_id', "ALTER TABLE orders ADD COLUMN razorpay_order_id VARCHAR(100) NULL", $applied, $skipped);

run($conn, 'society_maintenance_bills.refund_status', "ALTER TABLE society_maintenance_bills ADD COLUMN refund_status ENUM('none', 'requested', 'processed', 'rejected') NOT NULL DEFAULT 'none'", $applied, $skipped);
run($conn, 'society_maintenance_bills.refund_reason', "ALTER TABLE society_maintenance_bills ADD COLUMN refund_reason TEXT NULL", $applied, $skipped);
run($conn, 'society_maintenance_bills.refund_id', "ALTER TABLE society_maintenance_bills ADD COLUMN refund_id VARCHAR(100) NULL", $applied, $skipped);
run($conn, 'society_maintenance_bills.refunded_amount', "ALTER TABLE society_maintenance_bills ADD COLUMN refunded_amount DECIMAL(10,2) NULL", $applied, $skipped);
run($conn, 'society_maintenance_bills.razorpay_order_id', "ALTER TABLE society_maintenance_bills ADD COLUMN razorpay_order_id VARCHAR(100) NULL", $applied, $skipped);

$conn->close();

echo json_encode([
    'success' => true,
    'message' => 'Payment fixes schema migrated',
    'applied' => $applied,
    'skipped_or_already_exists' => $skipped,
]);
?>
