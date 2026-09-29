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
    $pincodeId = (int)($data['id'] ?? 0);

    if ($pincodeId <= 0) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Invalid pincode ID']);
        exit();
    }

    // Verify ownership
    $check = $conn->prepare('SELECT vendor_id FROM vendor_pincodes WHERE id = ?');
    $check->bind_param('i', $pincodeId);
    $check->execute();
    $row = $check->get_result()->fetch_assoc();
    $check->close();

    if (!$row || $row['vendor_id'] !== $vendorId) {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Not authorized']);
        exit();
    }

    // Delete
    $stmt = $conn->prepare('DELETE FROM vendor_pincodes WHERE id = ?');
    $stmt->bind_param('i', $pincodeId);
    $stmt->execute();
    $stmt->close();

    http_response_code(200);
    echo json_encode(['success' => true, 'message' => 'Pincode removed']);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Failed to delete pincode']);
}

$conn->close();
