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

if (!$data || !isset($data['society_id']) || !isset($data['flat_number'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'society_id and flat_number are required']);
    exit;
}

$society_id = (int)$data['society_id'];
requireSocietyManagerRole($society_id);

$flat_number = trim($data['flat_number']);
$building_id = isset($data['building_id']) && $data['building_id'] !== '' ? (int)$data['building_id'] : null;
$floor = isset($data['floor']) && $data['floor'] !== '' ? (int)$data['floor'] : null;
$occupancy_status = in_array($data['occupancy_status'] ?? 'vacant', ['occupied', 'vacant'], true)
    ? $data['occupancy_status']
    : 'vacant';

try {
    $pdo = new PDO(
        "mysql:host=localhost;dbname=digitrix_maha_maintain_pro;charset=utf8mb4",
        "digitrix_maha_user",
        "maha_user@70",
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    $stmt = $pdo->prepare('
        INSERT INTO society_flats (society_id, building_id, flat_number, floor, occupancy_status)
        VALUES (?, ?, ?, ?, ?)
    ');
    $stmt->execute([$society_id, $building_id, $flat_number, $floor, $occupancy_status]);

    echo json_encode([
        'success' => true,
        'message' => 'Flat added successfully',
        'flat_id' => $pdo->lastInsertId(),
    ]);
} catch (Exception $e) {
    if ($e->getCode() == 23000) {
        http_response_code(409);
        echo json_encode(['success' => false, 'error' => 'This flat number already exists in this society']);
        exit;
    }
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
