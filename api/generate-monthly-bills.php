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

if (!$data || !isset($data['society_id']) || !isset($data['period_month']) || !isset($data['amount'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'society_id, period_month (YYYY-MM) and amount are required']);
    exit;
}

$society_id = (int)$data['society_id'];
requireSocietyManagerRole($society_id);

$period_month = trim($data['period_month']);
$amount = (float)$data['amount'];
$due_date = $data['due_date'] ?? null;

if (!preg_match('/^\d{4}-\d{2}$/', $period_month)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'period_month must be in YYYY-MM format']);
    exit;
}

try {
    $pdo = new PDO(
        "mysql:host=localhost;dbname=digitrix_maha_maintain_pro;charset=utf8mb4",
        "digitrix_maha_user",
        "maha_user@70",
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    $flatsStmt = $pdo->prepare('SELECT id FROM society_flats WHERE society_id = ?');
    $flatsStmt->execute([$society_id]);
    $flatIds = $flatsStmt->fetchAll(PDO::FETCH_COLUMN);

    if (empty($flatIds)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'This society has no flats yet - add flats first']);
        exit;
    }

    $insertStmt = $pdo->prepare('
        INSERT INTO society_maintenance_bills (society_id, flat_id, period_month, amount, due_date, status)
        VALUES (?, ?, ?, ?, ?, "due")
        ON DUPLICATE KEY UPDATE amount = amount
    ');

    $created = 0;
    foreach ($flatIds as $flatId) {
        $insertStmt->execute([$society_id, $flatId, $period_month, $amount, $due_date]);
        if ($insertStmt->rowCount() > 0) $created++;
    }

    echo json_encode([
        'success' => true,
        'message' => "Bills generated for $created flat(s) for $period_month",
        'flats_billed' => count($flatIds),
        'bills_created' => $created,
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
