<?php
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    header('Content-Type: application/json');
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: POST, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization');
    header('Access-Control-Max-Age: 86400');
    http_response_code(200);
    exit();
}

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
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

// Create visitors table if not exists
$createTableQuery = "CREATE TABLE IF NOT EXISTS visitors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    purpose VARCHAR(255) NOT NULL,
    photo_url VARCHAR(500),
    gate VARCHAR(100),
    guard_name VARCHAR(255),
    flat_number VARCHAR(50),
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX(phone),
    INDEX(status),
    INDEX(created_at)
)";

$conn->query($createTableQuery);

try {
    $input = json_decode(file_get_contents('php://input'), true);

    $name = $input['name'] ?? null;
    $phone = $input['phone'] ?? null;
    $purpose = $input['purpose'] ?? null;
    $photoBase64 = $input['photoBase64'] ?? null;
    $gate = $input['gate'] ?? null;
    $guardName = $input['guard_name'] ?? null;
    $flatNumber = $input['flat_number'] ?? null;

    if (!$name || !$phone || !$purpose) {
        throw new Exception('Missing required fields: name, phone, purpose');
    }

    $photoUrl = null;

    // Save photo if provided
    if ($photoBase64) {
        $photoData = base64_decode(preg_replace('#^data:image/\w+;base64,#i', '', $photoBase64));

        $uploadDir = '/var/www/html/mahamaintainpro/api/photos/visitor_photos/';
        if (!is_dir($uploadDir)) {
            @mkdir($uploadDir, 0777, true);
        }

        $filename = 'visitor_' . uniqid() . '_' . time() . '.jpg';
        $filepath = $uploadDir . $filename;

        if (file_put_contents($filepath, $photoData)) {
            $photoUrl = 'https://' . $_SERVER['HTTP_HOST'] . '/mahamaintainpro/api/photos/visitor_photos/' . $filename;
        }
    }

    // Insert visitor record
    $query = "INSERT INTO visitors (name, phone, purpose, photo_url, gate, guard_name, flat_number)
              VALUES (?, ?, ?, ?, ?, ?, ?)";

    $stmt = $conn->prepare($query);
    if (!$stmt) throw new Exception('Prepare failed: ' . $conn->error);

    $stmt->bind_param('sssssss', $name, $phone, $purpose, $photoUrl, $gate, $guardName, $flatNumber);

    if (!$stmt->execute()) {
        throw new Exception('Insert failed: ' . $stmt->error);
    }

    $visitorId = $stmt->insert_id;
    $stmt->close();

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Visitor registered successfully',
        'visitor_id' => $visitorId,
        'photo_url' => $photoUrl
    ]);

} catch (Exception $e) {
    http_response_code(400);
    error_log("Save visitor error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

if (isset($conn)) {
    $conn->close();
}
?>
