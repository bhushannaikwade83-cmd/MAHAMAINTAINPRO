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

if (!$data || !isset($data['society_id']) || !isset($data['title']) || !isset($data['file_url'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'society_id, title and file_url are required']);
    exit;
}

$society_id = (int)$data['society_id'];
$token = requireSocietyManagerRole($society_id);

$title = trim($data['title']);
$file_url = trim($data['file_url']);
$uploaded_by = isset($data['uploaded_by']) ? (int)$data['uploaded_by'] : null;

try {
    $pdo = new PDO(
        "mysql:host=localhost;dbname=digitrix_maha_maintain_pro;charset=utf8mb4",
        "digitrix_maha_user",
        "maha_user@70",
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    $stmt = $pdo->prepare('INSERT INTO society_documents (society_id, title, file_url, uploaded_by) VALUES (?, ?, ?, ?)');
    $stmt->execute([$society_id, $title, $file_url, $uploaded_by]);

    echo json_encode([
        'success' => true,
        'message' => 'Document added successfully',
        'document_id' => $pdo->lastInsertId(),
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
