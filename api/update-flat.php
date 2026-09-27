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

$data = json_decode(file_get_contents('php://input'), true);

if (!$data || !isset($data['id']) || !isset($data['society_id'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'id and society_id are required']);
    exit;
}

$society_id = (int)$data['society_id'];
requireSocietyManagerRole($society_id);
$id = (int)$data['id'];

$updates = [];
$params = [];

if (isset($data['flat_number'])) {
    $updates[] = 'flat_number = ?';
    $params[] = trim($data['flat_number']);
}
if (isset($data['building_id'])) {
    $updates[] = 'building_id = ?';
    $params[] = $data['building_id'] !== '' ? (int)$data['building_id'] : null;
}
if (isset($data['floor'])) {
    $updates[] = 'floor = ?';
    $params[] = $data['floor'] !== '' ? (int)$data['floor'] : null;
}
if (isset($data['occupancy_status']) && in_array($data['occupancy_status'], ['occupied', 'vacant'], true)) {
    $updates[] = 'occupancy_status = ?';
    $params[] = $data['occupancy_status'];
}
if (array_key_exists('owner_member_id', $data)) {
    $updates[] = 'owner_member_id = ?';
    $params[] = $data['owner_member_id'] !== null && $data['owner_member_id'] !== '' ? (int)$data['owner_member_id'] : null;
}
if (array_key_exists('tenant_member_id', $data)) {
    $updates[] = 'tenant_member_id = ?';
    $params[] = $data['tenant_member_id'] !== null && $data['tenant_member_id'] !== '' ? (int)$data['tenant_member_id'] : null;
}

if (empty($updates)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'No fields to update']);
    exit;
}

try {
    $pdo = new PDO(
        "mysql:host=localhost;dbname=digitrix_maha_maintain_pro;charset=utf8mb4",
        "digitrix_maha_user",
        "maha_user@70",
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    $updates[] = 'updated_at = NOW()';
    $params[] = $id;
    $params[] = $society_id;

    $stmt = $pdo->prepare('UPDATE society_flats SET ' . implode(', ', $updates) . ' WHERE id = ? AND society_id = ?');
    $stmt->execute($params);

    if ($stmt->rowCount() === 0) {
        http_response_code(404);
        echo json_encode(['success' => false, 'error' => 'Flat not found']);
        exit;
    }

    echo json_encode(['success' => true, 'message' => 'Flat updated successfully']);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
