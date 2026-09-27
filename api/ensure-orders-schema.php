<?php
/**
 * Self-heals the `orders` table's columns. The live table on this server
 * pre-dates this session's work and was created with an older/different
 * schema - `CREATE TABLE IF NOT EXISTS` in create-order.php is a no-op
 * against an existing table, so it never actually added `phone_number`
 * (confirmed by the live error log: "Unknown column 'phone_number' in
 * 'WHERE'") or any of the columns added later (scheduled_at,
 * current_status, payment_method).
 *
 * Include this (require_once) in any endpoint that reads/writes
 * orders.phone_number, orders.scheduled_at, orders.current_status, or
 * orders.payment_method, right after opening $conn (mysqli) - cheap no-op
 * once the columns already exist.
 */
function ensureOrdersSchema(mysqli $conn): void {
    $conn->query("CREATE TABLE IF NOT EXISTS orders (
        id INT AUTO_INCREMENT PRIMARY KEY,
        order_id VARCHAR(50) UNIQUE NOT NULL,
        user_id VARCHAR(100),
        phone_number VARCHAR(20),
        address_id INT,
        total_amount DECIMAL(10, 2),
        service_count INT,
        scheduled_at DATETIME NULL,
        payment_status VARCHAR(50) DEFAULT 'pending',
        order_status VARCHAR(50) DEFAULT 'pending',
        current_status VARCHAR(50) DEFAULT 'requested',
        payment_id VARCHAR(100),
        payment_method VARCHAR(50),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )");

    $expectedColumns = [
        'phone_number' => 'VARCHAR(20) NULL',
        'address_id' => 'INT NULL',
        'total_amount' => 'DECIMAL(10, 2) NULL',
        'service_count' => 'INT NULL',
        'scheduled_at' => 'DATETIME NULL',
        'payment_status' => "VARCHAR(50) DEFAULT 'pending'",
        'order_status' => "VARCHAR(50) DEFAULT 'pending'",
        'current_status' => "VARCHAR(50) DEFAULT 'requested'",
        'payment_id' => 'VARCHAR(100) NULL',
        'payment_method' => 'VARCHAR(50) NULL',
        'razorpay_order_id' => 'VARCHAR(100) NULL',
        'discount_amount' => 'DECIMAL(10, 2) NULL DEFAULT 0',
        'coupon_code' => 'VARCHAR(50) NULL',
        'refund_status' => "VARCHAR(50) NULL DEFAULT 'none'",
    ];

    $existing = [];
    $result = $conn->query("SHOW COLUMNS FROM orders");
    while ($row = $result->fetch_assoc()) {
        $existing[$row['Field']] = true;
    }

    foreach ($expectedColumns as $column => $definition) {
        if (!isset($existing[$column])) {
            $conn->query("ALTER TABLE orders ADD COLUMN `$column` $definition");
        }
    }
}
?>
