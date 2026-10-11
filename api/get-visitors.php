<?php
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    header('Content-Type: application/json');
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization');
    header('Access-Control-Max-Age: 86400');
    http_response_code(200);
    exit();
}

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

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
    $phone_number = null;
    $status = null;
    $limit = 50;

    // Get parameters from POST or GET
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $data = json_decode(file_get_contents("php://input"), true);
        $phone_number = $data['phone_number'] ?? null;
        $status = $data['status'] ?? null;
        $limit = $data['limit'] ?? 50;
    } elseif ($_SERVER['REQUEST_METHOD'] === 'GET') {
        $phone_number = $_GET['phone_number'] ?? null;
        $status = $_GET['status'] ?? null;
        $limit = intval($_GET['limit'] ?? 50);
    }

    $visitors = [];

    // Build query
    $query = "SELECT id, name, phone, purpose, photo_url, gate, guard_name, flat_number, status, created_at, updated_at
              FROM visitors WHERE 1=1";

    $types = '';
    $params = [];

    // Add filters
    if ($phone_number) {
        $query .= " AND phone = ?";
        $types .= 's';
        $params[] = $phone_number;
    }

    if ($status) {
        $query .= " AND status = ?";
        $types .= 's';
        $params[] = $status;
    }

    $query .= " ORDER BY created_at DESC LIMIT ?";
    $types .= 'i';
    $params[] = $limit;

    // Prepare and execute
    $stmt = $conn->prepare($query);
    if (!$stmt) throw new Exception('Prepare failed: ' . $conn->error);

    if (!empty($params)) {
        $stmt->bind_param($types, ...$params);
    }

    $stmt->execute();
    $result = $stmt->get_result();

    while ($row = $result->fetch_assoc()) {
        $visitors[] = $row;
    }

    $stmt->close();

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'visitors' => $visitors,
        'count' => count($visitors),
        'filters' => [
            'phone' => $phone_number,
            'status' => $status,
            'limit' => $limit
        ]
    ]);

} catch (Exception $e) {
    http_response_code(500);
    error_log("Get visitors error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
