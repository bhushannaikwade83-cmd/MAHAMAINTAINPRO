<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
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

try {
    $input = json_decode(file_get_contents('php://input'), true);

    $name = trim($input['name'] ?? '');
    $phone = trim($input['phone'] ?? '');
    $society_id = intval($input['society_id'] ?? 0);

    if (empty($name) || empty($phone)) {
        throw new Exception('Name and phone are required');
    }

    if (!preg_match('/^[0-9]{10}$/', $phone)) {
        throw new Exception('Phone must be 10 digits');
    }

    if ($society_id <= 0) {
        throw new Exception('Society ID is required');
    }

    // Check if phone already exists in society_customers_individual or society_secretaries
    $stmt = $pdo->prepare("SELECT id FROM society_customers_individual WHERE phone = ?");
    $stmt->execute([$phone]);
    if ($stmt->fetch()) {
        throw new Exception('Phone number already registered');
    }

    $stmt = $pdo->prepare("SELECT id FROM society_secretaries WHERE phone = ?");
    $stmt->execute([$phone]);
    if ($stmt->fetch()) {
        throw new Exception('Phone number already has a pending registration');
    }

    // Insert into society_secretaries
    $stmt = $pdo->prepare("INSERT INTO society_secretaries (society_id, name, phone, status, created_at, updated_at)
                           VALUES (?, ?, ?, 'pending', NOW(), NOW())");
    $stmt->execute([$society_id, $name, $phone]);

    http_response_code(201);
    echo json_encode([
        'success' => true,
        'message' => 'Registration submitted. Awaiting admin approval.',
        'status' => 'pending'
    ]);

} catch (Exception $e) {
    http_response_code(400);
    error_log("Registration error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
?>
