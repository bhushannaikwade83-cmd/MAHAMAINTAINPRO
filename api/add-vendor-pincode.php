<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
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
    $data = json_decode(file_get_contents('php://input'), true);
    $pincode = trim($data['pincode'] ?? '');

    if (!preg_match('/^\d{5,6}$/', $pincode)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Invalid pincode format']);
        exit();
    }

    // Check if already exists
    $check = $conn->prepare('SELECT id FROM vendor_pincodes WHERE vendor_id = ? AND pincode = ?');
    $check->bind_param('ss', $vendorId, $pincode);
    $check->execute();
    if ($check->get_result()->fetch_assoc()) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'This pincode is already registered']);
        exit();
    }
    $check->close();

    // Insert
    $stmt = $conn->prepare('INSERT INTO vendor_pincodes (vendor_id, pincode) VALUES (?, ?)');
    $stmt->bind_param('ss', $vendorId, $pincode);
    if (!$stmt->execute()) {
        throw new Exception('Insert failed: ' . $stmt->error);
    }
    $insertId = $conn->insert_id;
    $stmt->close();

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Pincode added successfully',
        'pincode' => [
            'id' => $insertId,
            'pincode' => $pincode,
            'created_at' => date('Y-m-d H:i:s'),
        ],
    ]);
} catch (Exception $e) {
    http_response_code(500);
    error_log('Add pincode error: ' . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'Failed to add pincode']);
}

$conn->close();
