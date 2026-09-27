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

if (!$data || !isset($data['society_id']) || !isset($data['title']) || !isset($data['description'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'society_id, title and description are required']);
    exit;
}

$society_id = (int)$data['society_id'];
$token = requireSocietyManagerRole($society_id);

$title = trim($data['title']);
$description = trim($data['description']);
$category = trim($data['category'] ?? 'general');
$expires_at = $data['expires_at'] ?? null;
$posted_by = isset($data['posted_by']) ? (int)$data['posted_by'] : null;

try {
    $pdo = new PDO(
        "mysql:host=localhost;dbname=digitrix_maha_maintain_pro;charset=utf8mb4",
        "digitrix_maha_user",
        "maha_user@70",
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    $stmt = $pdo->prepare('
        INSERT INTO society_notices (society_id, title, description, category, posted_by, expires_at)
        VALUES (?, ?, ?, ?, ?, ?)
    ');
    $stmt->execute([$society_id, $title, $description, $category, $posted_by, $expires_at]);

    echo json_encode([
        'success' => true,
        'message' => 'Notice posted successfully',
        'notice_id' => $pdo->lastInsertId(),
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
