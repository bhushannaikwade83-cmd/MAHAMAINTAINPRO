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
    // Create society_secretaries table
    $createSecretaries = "CREATE TABLE IF NOT EXISTS society_secretaries (
        id INT AUTO_INCREMENT PRIMARY KEY,
        secretary_id VARCHAR(100) UNIQUE NOT NULL,
        user_id INT,
        name VARCHAR(255) NOT NULL,
        phone VARCHAR(20) NOT NULL,
        status VARCHAR(50) DEFAULT 'not_active',
        approval_status VARCHAR(50) DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        KEY idx_user_id (user_id)
    )";
    $conn->query($createSecretaries);

    // Create society_services table
    $createServices = "CREATE TABLE IF NOT EXISTS society_services (
        id INT AUTO_INCREMENT PRIMARY KEY,
        secretary_id VARCHAR(100) NOT NULL,
        service_name VARCHAR(255) NOT NULL,
        service_icon VARCHAR(50),
        is_active BOOLEAN DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (secretary_id) REFERENCES society_secretaries(secretary_id)
    )";
    $conn->query($createServices);

    // Insert default 6 society services
    $services = [
        ['Bill Management', '📄'],
        ['Visitor Management', '🚪'],
        ['Complaints', '📋'],
        ['Parking Management', '🚗'],
        ['Tenant Management', '👥'],
        ['Emergency SOS', '🚨']
    ];

    $stmt = $conn->prepare("INSERT INTO society_services (secretary_id, service_name, service_icon, is_active)
                            VALUES ('demo_society', ?, ?, 0)
                            ON DUPLICATE KEY UPDATE is_active=0");

    foreach ($services as $service) {
        $stmt->bind_param("ss", $service[0], $service[1]);
        $stmt->execute();
    }
    $stmt->close();

    echo json_encode([
        'success' => true,
        'message' => 'Society system migrated successfully',
        'tables' => ['society_secretaries', 'society_services'],
        'services' => $services
    ]);

} catch (Exception $e) {
    http_response_code(500);
    error_log("Migration error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
