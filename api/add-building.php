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

if (!$data || !isset($data['society_id']) || !isset($data['name'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'society_id and name are required']);
    exit;
}

$society_id = (int)$data['society_id'];
requireSocietyManagerRole($society_id);

$name = trim($data['name']);
$wing = isset($data['wing']) ? trim($data['wing']) : null;
$total_floors = isset($data['total_floors']) ? (int)$data['total_floors'] : null;

try {
    $pdo = new PDO(
        "mysql:host=localhost;dbname=digitrix_maha_maintain_pro;charset=utf8mb4",
        "digitrix_maha_user",
        "maha_user@70",
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    $stmt = $pdo->prepare('INSERT INTO society_buildings (society_id, name, wing, total_floors) VALUES (?, ?, ?, ?)');
    $stmt->execute([$society_id, $name, $wing, $total_floors]);

    echo json_encode([
        'success' => true,
        'message' => 'Building added successfully',
        'building_id' => $pdo->lastInsertId(),
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
