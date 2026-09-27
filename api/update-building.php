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

if (isset($data['name'])) {
    $updates[] = 'name = ?';
    $params[] = trim($data['name']);
}
if (isset($data['wing'])) {
    $updates[] = 'wing = ?';
    $params[] = trim($data['wing']);
}
if (isset($data['total_floors'])) {
    $updates[] = 'total_floors = ?';
    $params[] = (int)$data['total_floors'];
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

    $params[] = $id;
    $params[] = $society_id;
    $stmt = $pdo->prepare('UPDATE society_buildings SET ' . implode(', ', $updates) . ' WHERE id = ? AND society_id = ?');
    $stmt->execute($params);

    if ($stmt->rowCount() === 0) {
        http_response_code(404);
        echo json_encode(['success' => false, 'error' => 'Building not found']);
        exit;
    }

    echo json_encode(['success' => true, 'message' => 'Building updated successfully']);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
