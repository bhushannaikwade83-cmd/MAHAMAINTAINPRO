<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'jwt-auth.php';
$vendorToken = requireVendorRole();
$vendorId = (string) $vendorToken['vendor_id'];

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
    $stmt = $conn->prepare('SELECT id, pincode, created_at FROM vendor_pincodes WHERE vendor_id = ? ORDER BY pincode');
    $stmt->bind_param('s', $vendorId);
    $stmt->execute();
    $result = $stmt->get_result();
    $pincodes = [];
    while ($row = $result->fetch_assoc()) {
        $pincodes[] = [
            'id' => (int)$row['id'],
            'pincode' => $row['pincode'],
            'created_at' => $row['created_at'],
        ];
    }
    $stmt->close();

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'pincodes' => $pincodes,
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Failed to fetch pincodes']);
}

$conn->close();
