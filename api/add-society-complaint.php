<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Any resident can raise a complaint, but user_id is derived from the
// JWT's phone number - never trusted from the client - so nobody can
// submit a complaint as someone else.
require_once 'jwt-auth.php';
$authToken = verifyJWTToken();

$data = json_decode(file_get_contents('php://input'), true);

$society_id = intval($data['society_id'] ?? 0);
$category = trim($data['category'] ?? '');
$description = trim($data['description'] ?? '');
$flat_id = isset($data['flat_id']) && $data['flat_id'] !== '' ? (int)$data['flat_id'] : null;
$priority = in_array($data['priority'] ?? 'medium', ['low', 'medium', 'high'], true) ? $data['priority'] : 'medium';
$photo_url = isset($data['photo_url']) && $data['photo_url'] !== '' ? trim($data['photo_url']) : null;
$video_url = isset($data['video_url']) && $data['video_url'] !== '' ? trim($data['video_url']) : null;

if ($society_id <= 0 || $category === '' || $description === '') {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'society_id, category and description are required']);
    exit;
}

try {
    $pdo = new PDO(
        "mysql:host=localhost;dbname=digitrix_maha_maintain_pro;charset=utf8mb4",
        "digitrix_maha_user",
        "maha_user@70",
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    $userStmt = $pdo->prepare('SELECT id FROM individuals WHERE phone_number = ?');
    $userStmt->execute([$authToken['phone_number']]);
    $userRow = $userStmt->fetch(PDO::FETCH_ASSOC);
    if (!$userRow) {
        http_response_code(404);
        echo json_encode(['success' => false, 'error' => 'User account not found']);
        exit;
    }
    $user_id = $userRow['id'];

    // Self-heal: video attachments predate this table's original schema.
    $checkCol = $pdo->query("SHOW COLUMNS FROM society_complaints LIKE 'video_url'");
    if ($checkCol->rowCount() === 0) {
        $pdo->exec("ALTER TABLE society_complaints ADD COLUMN video_url VARCHAR(500) NULL");
    }

    $stmt = $pdo->prepare('
        INSERT INTO society_complaints (society_id, user_id, flat_id, category, description, priority, photo_url, video_url)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ');
    $stmt->execute([$society_id, $user_id, $flat_id, $category, $description, $priority, $photo_url, $video_url]);

    echo json_encode([
        'success' => true,
        'message' => 'Complaint submitted successfully',
        'complaint_id' => $pdo->lastInsertId(),
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
