<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit();
}

try {
    $user_id = intval($_GET['user_id'] ?? $_POST['user_id'] ?? 0);

    if ($user_id <= 0) {
        throw new Exception('User ID is required');
    }

    $stmt = $conn->prepare("SELECT id, user_id, society_id, secretary_name, phone, is_committee, is_enabled, designation, created_at FROM society_customers_individual WHERE user_id = ?");
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $member = $result->fetch_assoc();
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'exists' => true,
            'member' => $member
        ]);
    } else {
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'exists' => false,
            'member' => null
        ]);
    }

    $stmt->close();

} catch (Exception $e) {
    http_response_code(400);
    error_log("Check member error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
