<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
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

    $data = json_decode(file_get_contents('php://input'), true);

    if (!$data || !isset($data['society_id']) || !isset($data['secretary_name']) || !isset($data['phone'])) {
        throw new Exception("Missing required fields: society_id, secretary_name, phone");
    }

    $society_id = $data['society_id'];
    $secretary_name = $data['secretary_name'];
    $phone = $data['phone'];
    $is_committee = isset($data['is_committee']) ? (int)$data['is_committee'] : 0;
    $designation = isset($data['designation']) ? $data['designation'] : 'MEMBER';

    if (!preg_match('/^[0-9]{10}$/', $phone)) {
        throw new Exception("Phone must be 10 digits");
    }

    // Check if phone already exists in society_customers_individual
    $stmt = $pdo->prepare("SELECT id FROM society_customers_individual WHERE phone = ?");
    $stmt->execute([$phone]);
    if ($stmt->fetch()) {
        throw new Exception("Phone number already registered");
    }

    // Get user_id from individuals table using phone number
    $stmt = $pdo->prepare("SELECT id FROM individuals WHERE phone = ?");
    $stmt->execute([$phone]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    $user_id = $user ? $user['id'] : null;

    // Insert into society_customers_individual with user_id (can be null for offline members)
    $stmt = $pdo->prepare("
        INSERT INTO society_customers_individual
        (society_id, user_id, secretary_name, phone, is_committee, designation, is_enabled, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, 1, NOW(), NOW())
    ");
    $stmt->execute([$society_id, $user_id, $secretary_name, $phone, $is_committee, $designation]);

    $member_id = $pdo->lastInsertId();

    echo json_encode([
        'success' => true,
        'message' => 'Member added successfully',
        'member_id' => $member_id,
        'user_id' => $user_id,
        'note' => $user_id ? 'User found and linked' : 'Phone not in individuals table (offline member)'
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>
