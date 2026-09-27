<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Read-only directory of a society's buildings/wings - restricted to
// members of THIS society only.
require_once 'jwt-auth.php';

$society_id = (int)($_GET['society_id'] ?? 0);

if ($society_id <= 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'society_id is required']);
    exit;
}

requireSocietyMembership($society_id);

try {
    $conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');
    if ($conn->connect_error) {
        throw new Exception('Database connection failed');
    }

    $stmt = $conn->prepare("SELECT id, society_id, name, wing, total_floors, created_at FROM society_buildings WHERE society_id = ? ORDER BY name ASC");
    $stmt->bind_param('i', $society_id);
    $stmt->execute();
    $result = $stmt->get_result();

    $buildings = [];
    while ($row = $result->fetch_assoc()) {
        $buildings[] = $row;
    }

    echo json_encode(['success' => true, 'buildings' => $buildings, 'total' => count($buildings)]);
    $stmt->close();
    $conn->close();
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
