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

    $data = json_decode(file_get_contents('php://input'), true);
    if (!isset($data['name']) || !isset($data['price'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'name and price are required']);
        exit;
    }

    $conn->begin_transaction();

    $description = $data['description'] ?? null;
    $imagePath = $data['image_path'] ?? null;
    $isActive = isset($data['is_active']) ? (int)(bool)$data['is_active'] : 1;
    $stmt = $conn->prepare("INSERT INTO service_packages (name, description, image_path, price, is_active) VALUES (?, ?, ?, ?, ?)");
    $stmt->bind_param('sssdi', $data['name'], $description, $imagePath, $data['price'], $isActive);
    $stmt->execute();
    $packageId = $stmt->insert_id;
    $stmt->close();

    $serviceIds = $data['service_ids'] ?? [];
    if (is_array($serviceIds) && !empty($serviceIds)) {
        $itemStmt = $conn->prepare("INSERT INTO service_package_items (package_id, service_id) VALUES (?, ?)");
        foreach ($serviceIds as $serviceId) {
            $sid = (int)$serviceId;
            $itemStmt->bind_param('ii', $packageId, $sid);
            $itemStmt->execute();
        }
        $itemStmt->close();
    }

    $conn->commit();

    echo json_encode(['success' => true, 'message' => 'Package added successfully', 'id' => $packageId]);
    $conn->close();
} catch (Exception $e) {
    if (isset($conn)) $conn->rollback();
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
