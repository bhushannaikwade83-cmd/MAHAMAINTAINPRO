<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $pdo = new PDO(
        "mysql:host=localhost;dbname=digitrix_maha_maintain_pro;charset=utf8mb4",
        "digitrix_maha_user",
        "maha_user@70",
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit;
}

$phone = $_GET['phone'] ?? $_POST['phone'] ?? null;

if (!$phone || !preg_match('/^[0-9]{10}$/', $phone)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Valid 10-digit phone number required']);
    exit;
}

try {
    // Check if phone exists in society_customers_individual
    $stmt = $pdo->prepare("SELECT id, user_id, society_id, secretary_name, phone, is_committee, is_enabled, designation FROM society_customers_individual WHERE phone = ?");
    $stmt->execute([$phone]);
    $memberRecord = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($memberRecord) {
        $is_enabled = (int)$memberRecord['is_enabled'];
        if ($is_enabled === 1) {
            // User is fully enabled and can access dashboard
            echo json_encode([
                'success' => true,
                'status' => 'active',
                'message' => 'User is active',
                'member' => $memberRecord
            ]);
        } else {
            // User exists but is not enabled yet (pending approval)
            echo json_encode([
                'success' => true,
                'status' => 'pending_approval',
                'message' => 'User is pending admin approval',
                'member' => $memberRecord
            ]);
        }
        exit;
    }

    // Check if phone exists in society_secretaries (pending registration)
    $stmt = $pdo->prepare("SELECT id, phone, name, status FROM society_secretaries WHERE phone = ?");
    $stmt->execute([$phone]);
    $secretaryRecord = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($secretaryRecord) {
        echo json_encode([
            'success' => true,
            'status' => 'pending_registration',
            'message' => 'Registration is pending admin approval',
            'secretary' => $secretaryRecord
        ]);
        exit;
    }

    // Phone not found anywhere - new user
    echo json_encode([
        'success' => true,
        'status' => 'new_user',
        'message' => 'New user - please register'
    ]);

} catch (Exception $e) {
    http_response_code(500);
    error_log("Check registration status error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
?>
