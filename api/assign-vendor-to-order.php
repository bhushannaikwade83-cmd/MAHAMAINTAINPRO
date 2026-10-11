<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit();
}

try {
    $input = json_decode(file_get_contents('php://input'), true);

    $orderId = $input['order_id'] ?? null;
    $vendorId = $input['vendor_id'] ?? null;

    if (!$orderId) {
        throw new Exception('order_id required');
    }

    // Get order details including address to find pincode
    $orderQuery = "SELECT address_id, phone_number FROM orders WHERE order_id = ?";
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

    $addressId = $orderData['address_id'];
    $phoneNumber = $orderData['phone_number'];

    // Get pincode from address
    $addressQuery = "SELECT pincode, area FROM addresses WHERE id = ? AND phone_number = ?";
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

    // If vendor_id not provided, find vendors who serve this pincode
    if (!$vendorId) {
        // Try to find a vendor who serves this pincode
        $vendorQuery = "
            SELECT DISTINCT v.vendor_id, v.name
            FROM vendors v
            INNER JOIN vendor_pincodes vp ON v.vendor_id = vp.vendor_id
            WHERE vp.pincode = ? AND v.status = 'active' AND vp.is_active = 1
            ORDER BY v.total_services DESC
            LIMIT 1
        ";
        $stmt = $conn->prepare($vendorQuery);
        if (!$stmt) {
            throw new Exception('Prepare failed: ' . $conn->error);
        }
        $stmt->bind_param('s', $pincode);
        $stmt->execute();
        $vendorResult = $stmt->get_result();

        if ($vendorResult->num_rows > 0) {
            $row = $vendorResult->fetch_assoc();
            $vendorId = $row['vendor_id'];
            $vendorName = $row['name'];
        } else {
            // No vendor found for this pincode - try fallback
            $fallbackQuery = "SELECT vendor_id, name FROM vendors WHERE status = 'active' ORDER BY total_services DESC LIMIT 1";
            $fallbackResult = $conn->query($fallbackQuery);

            if ($fallbackResult && $fallbackResult->num_rows > 0) {
                $row = $fallbackResult->fetch_assoc();
                $vendorId = $row['vendor_id'];
                $vendorName = $row['name'];
                $message = 'No vendor found for pincode ' . $pincode . ' - assigned: ' . $vendorName;
            } else {
                // No vendors available at all
                echo json_encode([
                    'success' => true,
                    'message' => 'No vendors available for pincode ' . $pincode,
                    'order_id' => $orderId,
                    'pincode' => $pincode,
                    'vendor_assigned' => false,
                ]);
                $conn->close();
                exit();
            }
        }
        $stmt->close();
    }

    // Verify vendor exists
    $vendorCheck = "SELECT vendor_id, name FROM vendors WHERE vendor_id = ?";
    $stmt = $conn->prepare($vendorCheck);
    if (!$stmt) {
        throw new Exception('Prepare failed: ' . $conn->error);
    }
    $stmt->bind_param('s', $vendorId);
    $stmt->execute();
    $vendorCheckResult = $stmt->get_result();
    $stmt->close();

    if ($vendorCheckResult->num_rows === 0) {
        throw new Exception('Vendor not found');
    }

    // Assign vendor to order
    $updateQuery = "UPDATE orders SET vendor_id = ?, vendor_status = 'pending' WHERE order_id = ?";
    $stmt = $conn->prepare($updateQuery);
    if (!$stmt) {
        throw new Exception('Prepare failed: ' . $conn->error);
    }
    $stmt->bind_param('ss', $vendorId, $orderId);

    if (!$stmt->execute()) {
        throw new Exception('Update failed: ' . $stmt->error);
    }
    $stmt->close();

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => $message ?? 'Vendor assigned to order for pincode ' . $pincode,
        'order_id' => $orderId,
        'vendor_id' => $vendorId,
        'pincode' => $pincode,
        'vendor_status' => 'pending',
    ]);

} catch (Exception $e) {
    http_response_code(400);
    error_log("Assign vendor error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
