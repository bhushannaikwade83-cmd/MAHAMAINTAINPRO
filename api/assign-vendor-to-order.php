<?php
/**
 * Dispatches a paid/placed order to the vendor app's real job queue.
 *
 * The vendor app (maha-vendor-app) reads jobs from its own `bookings` table
 * (broadcast model: unassigned jobs, filtered by category, first vendor to
 * accept claims it - see server/get-vendor-jobs.php / respond-to-job.php).
 * This endpoint used to only set orders.vendor_id, which nothing on the
 * vendor side ever reads - so a customer's order never actually reached a
 * technician. This now creates one `bookings` row per order_item (one per
 * service in the cart), linked back to this order via bookings.order_id,
 * so vendor-side status changes can be synced back to order_status.
 */
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Any authenticated caller could otherwise dispatch ANY order_id to the
// vendor job queue just by guessing/enumerating it - require a valid
// session and confirm the order actually belongs to that phone number.
require_once 'jwt-auth.php';
$authToken = verifyJWTToken();

$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);

require_once 'ensure-orders-schema.php';
if (!$conn->connect_error) {
    ensureOrdersSchema($conn);
}

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit();
}

// Self-heal: bookings needs an order_id column to trace a vendor's job back
// to the customer's order (bookings-schema.sql, in the vendor app repo,
// doesn't define this since it predates this integration).
function ensureColumn(mysqli $conn, string $table, string $column, string $definition): void {
    $check = $conn->prepare(
        "SELECT COUNT(*) AS n FROM information_schema.columns
         WHERE table_schema = DATABASE() AND table_name = ? AND column_name = ?"
    );
    $check->bind_param('ss', $table, $column);
    $check->execute();
    $exists = (int) $check->get_result()->fetch_assoc()['n'] > 0;
    $check->close();
    if (!$exists) {
        $conn->query("ALTER TABLE `$table` ADD COLUMN `$column` $definition");
    }
}
ensureColumn($conn, 'bookings', 'order_id', 'VARCHAR(50) NULL, ADD INDEX idx_order_id (order_id)');
ensureColumn($conn, 'bookings', 'pincode', 'VARCHAR(10) NULL');

try {
    $input = json_decode(file_get_contents('php://input'), true);

    $orderId = $input['order_id'] ?? null;

    if (!$orderId) {
        throw new Exception('order_id required');
    }

    // Get order details including address to find pincode
    $orderQuery = "SELECT address_id, phone_number, payment_method, scheduled_at FROM orders WHERE order_id = ?";
    $stmt = $conn->prepare($orderQuery);
    if (!$stmt) {
        throw new Exception('Prepare failed: ' . $conn->error);
    }
    $stmt->bind_param('s', $orderId);
    $stmt->execute();
    $orderResult = $stmt->get_result();
    $orderData = $orderResult->fetch_assoc();
    $stmt->close();

    if (!$orderData) {
        throw new Exception('Order not found');
    }

    if ($orderData['phone_number'] !== $authToken['phone_number']) {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'This order does not belong to you']);
        exit();
    }

    $addressId = $orderData['address_id'];
    $phoneNumber = $orderData['phone_number'];
    $scheduledAt = $orderData['scheduled_at'] ?? null;
    $paymentMethod = strtoupper($orderData['payment_method'] ?? 'UPI');
    if (!in_array($paymentMethod, ['UPI', 'CASH', 'ONLINE'], true)) {
        $paymentMethod = 'ONLINE';
    }

    // Get full address for the technician
    $addressQuery = "SELECT full_address, building_name, street, area, pincode, latitude, longitude FROM addresses WHERE id = ? AND phone_number = ?";
    $stmt = $conn->prepare($addressQuery);
    if (!$stmt) {
        throw new Exception('Prepare failed: ' . $conn->error);
    }
    $stmt->bind_param('is', $addressId, $phoneNumber);
    $stmt->execute();
    $addressResult = $stmt->get_result();
    $addressData = $addressResult->fetch_assoc();
    $stmt->close();

    $pincode = $addressData['pincode'] ?? 'unknown';
    $fullAddress = $addressData['full_address']
        ?? trim(implode(', ', array_filter([
            $addressData['building_name'] ?? null,
            $addressData['street'] ?? null,
            $addressData['area'] ?? null,
            $addressData['pincode'] ?? null,
        ])));
    $latitude = $addressData['latitude'] ?? null;
    $longitude = $addressData['longitude'] ?? null;

    // Customer name for the technician's job card
    $customerName = 'Customer';
    $nameStmt = $conn->prepare("SELECT full_name FROM individuals WHERE phone_number = ?");
    if ($nameStmt) {
        $nameStmt->bind_param('s', $phoneNumber);
        $nameStmt->execute();
        $nameRow = $nameStmt->get_result()->fetch_assoc();
        $nameStmt->close();
        if ($nameRow && !empty($nameRow['full_name'])) {
            $customerName = $nameRow['full_name'];
        }
    }

    // One bookings row per service in the cart, broadcast (vendor_id NULL)
    // to every vendor who services that category - matches the existing,
    // already-working vendor app accept/reject flow.
    $itemsStmt = $conn->prepare("SELECT service_id, service_name, category, subtotal FROM order_items WHERE order_id = ?");
    $itemsStmt->bind_param('s', $orderId);
    $itemsStmt->execute();
    $itemsResult = $itemsStmt->get_result();

    $bookingIds = [];
    $insertStmt = $conn->prepare(
        "INSERT INTO bookings (customer_name, customer_phone, category_id, service_type, address, latitude, longitude, amount, payment_mode, scheduled_at, status, order_id, pincode)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'REQUESTED', ?, ?)"
    );
    if (!$insertStmt) {
        throw new Exception('Prepare failed: ' . $conn->error);
    }

    while ($item = $itemsResult->fetch_assoc()) {
        // order_items.category stores the numeric category_id (despite the
        // column name) - see service_category_screen.dart's addItem call.
        $categoryId = (int) $item['category'];
        if ($categoryId <= 0) {
            continue;
        }
        $serviceType = $item['service_name'] ?? 'Service';
        $amount = (float) $item['subtotal'];

        $insertStmt->bind_param(
            'ssissddddsss',
            $customerName,
            $phoneNumber,
            $categoryId,
            $serviceType,
            $fullAddress,
            $latitude,
            $longitude,
            $amount,
            $paymentMethod,
            $scheduledAt,
            $orderId,
            $pincode
        );
        if ($insertStmt->execute()) {
            $bookingIds[] = $conn->insert_id;
        }
    }
    $itemsStmt->close();
    $insertStmt->close();

    if (empty($bookingIds)) {
        echo json_encode([
            'success' => true,
            'message' => 'No valid order items to dispatch',
            'order_id' => $orderId,
            'bookings_created' => 0,
        ]);
        $conn->close();
        exit();
    }

    require_once 'push-notification-helper.php';
    sendPushToPhone(
        $conn,
        $phoneNumber,
        'Technician assigned',
        'We are dispatching a technician for your order. You will be notified once one accepts.',
        ['type' => 'technician_assigned', 'order_id' => $orderId]
    );

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Order dispatched to ' . count($bookingIds) . ' job(s) for available technicians',
        'order_id' => $orderId,
        'pincode' => $pincode,
        'bookings_created' => count($bookingIds),
        'booking_ids' => $bookingIds,
    ]);

} catch (Exception $e) {
    http_response_code(400);
    error_log("Assign vendor error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'An internal error occurred. Please try again.']);
}

$conn->close();
?>
