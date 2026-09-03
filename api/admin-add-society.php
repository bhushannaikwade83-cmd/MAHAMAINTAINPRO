<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
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

try {
    $pdo = new PDO(
        "mysql:host=$servername;dbname=$database;charset=utf8mb4",
        $db_username,
        $db_password,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Database connection failed']);
    exit;
}

$data = json_decode(file_get_contents('php://input'), true);

if (!$data || !isset($data['name']) || !isset($data['address']) || !isset($data['city'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Missing required fields']);
    exit;
}

$name = $data['name'];
$address = $data['address'];
$city = $data['city'];
$postal_code = $data['postal_code'] ?? null;

try {
    $stmt = $pdo->prepare('
        INSERT INTO societies (name, address, city, postal_code, created_at, updated_at)
        VALUES (?, ?, ?, ?, NOW(), NOW())
    ');

    $stmt->execute([$name, $address, $city, $postal_code]);
    $societyId = $pdo->lastInsertId();

    echo json_encode([
        'success' => true,
        'message' => 'Society added successfully',
        'society_id' => $societyId
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
