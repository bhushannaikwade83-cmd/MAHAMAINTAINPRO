<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Lets the Society Module's "Assign Vendor" picker use real registered
// vendor accounts (vendors table, shared with maha-vendor-app) instead of
// a free-text name. Any logged-in committee/secretary can list them.
require_once 'jwt-auth.php';
verifyJWTToken();

try {
    $conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');
    if ($conn->connect_error) {
        throw new Exception('Database connection failed');
    }

    $result = $conn->query("SELECT id, vendor_id, name, phone, rating, status FROM vendors WHERE status = 'active' ORDER BY name ASC");

    $vendors = [];
    while ($row = $result->fetch_assoc()) {
        $vendors[] = $row;
    }

    echo json_encode(['success' => true, 'vendors' => $vendors, 'total' => count($vendors)]);
    $conn->close();
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
