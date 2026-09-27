<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'jwt-auth.php';
requireAdminRole();

try {
    $conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');
    if ($conn->connect_error) {
        throw new Exception('Database connection failed');
    }

    $conn->query("CREATE TABLE IF NOT EXISTS service_packages (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        description TEXT NULL,
        image_path VARCHAR(500) NULL,
        price DECIMAL(10,2) NOT NULL DEFAULT 0,
        is_active TINYINT(1) NOT NULL DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )");
    $conn->query("CREATE TABLE IF NOT EXISTS service_package_items (
        id INT AUTO_INCREMENT PRIMARY KEY,
        package_id INT NOT NULL,
        service_id INT NOT NULL,
        UNIQUE KEY uniq_package_service (package_id, service_id),
        FOREIGN KEY (package_id) REFERENCES service_packages(id) ON DELETE CASCADE,
        FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE
    )");

    $result = $conn->query("SELECT * FROM service_packages ORDER BY id DESC");
    $packages = [];
    while ($row = $result->fetch_assoc()) {
        $itemStmt = $conn->prepare("SELECT sp.service_id, s.name AS service_name FROM service_package_items sp JOIN services s ON s.id = sp.service_id WHERE sp.package_id = ?");
        $itemStmt->bind_param('i', $row['id']);
        $itemStmt->execute();
        $itemsResult = $itemStmt->get_result();
        $items = [];
        while ($item = $itemsResult->fetch_assoc()) {
            $items[] = $item;
        }
        $itemStmt->close();
        $row['services'] = $items;
        $packages[] = $row;
    }

    echo json_encode(['success' => true, 'packages' => $packages, 'total' => count($packages)]);
    $conn->close();
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
