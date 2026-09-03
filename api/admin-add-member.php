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
    $servername = "localhost";
    $db_username = "digitrix_maha_user";
    $db_password = "maha_user@70";
    $database = "digitrix_maha_maintain_pro";

    $conn = new mysqli($servername, $db_username, $db_password, $database);

    if ($conn->connect_error) {
        throw new Exception("Connection failed: " . $conn->connect_error);
    }

    $data = json_decode(file_get_contents('php://input'), true);

    if (!$data || !isset($data['society_id']) || !isset($data['secretary_name']) || !isset($data['phone'])) {
        throw new Exception("Missing required fields: society_id, secretary_name, phone");
    }

    $society_id = $data['society_id'];
    $secretary_name = $data['secretary_name'];
    $phone = $data['phone'];
    $is_committee = isset($data['is_committee']) ? (int)$data['is_committee'] : 0;

    $query = "INSERT INTO society_customers_individual (society_id, secretary_name, phone, is_committee, is_enabled, approval_status, created_at, updated_at)
              VALUES (?, ?, ?, ?, 1, 'pending', NOW(), NOW())";

    $stmt = $conn->prepare($query);
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }

    $stmt->bind_param("issi", $society_id, $secretary_name, $phone, $is_committee);

    if (!$stmt->execute()) {
        throw new Exception("Execute failed: " . $stmt->error);
    }

    $member_id = $conn->insert_id;

    echo json_encode([
        'success' => true,
        'message' => 'Member added successfully',
        'member_id' => $member_id
    ]);

    $stmt->close();
    $conn->close();
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>
