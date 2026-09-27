<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Read-only flat directory - restricted to members of THIS society only.
require_once 'jwt-auth.php';

$society_id = (int)($_GET['society_id'] ?? 0);
$building_id = isset($_GET['building_id']) ? (int)$_GET['building_id'] : null;

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

    $query = "SELECT f.id, f.society_id, f.building_id, b.name AS building_name, b.wing,
                     f.flat_number, f.floor, f.occupancy_status,
                     f.owner_member_id, owner.secretary_name AS owner_name,
                     f.tenant_member_id, tenant.secretary_name AS tenant_name,
                     f.created_at
              FROM society_flats f
              LEFT JOIN society_buildings b ON b.id = f.building_id
              LEFT JOIN society_customers_individual owner ON owner.id = f.owner_member_id
              LEFT JOIN society_customers_individual tenant ON tenant.id = f.tenant_member_id
              WHERE f.society_id = ?";

    if ($building_id) {
        $query .= " AND f.building_id = ?";
    }
    $query .= " ORDER BY f.flat_number ASC";

    $stmt = $conn->prepare($query);
    if ($building_id) {
        $stmt->bind_param('ii', $society_id, $building_id);
    } else {
        $stmt->bind_param('i', $society_id);
    }
    $stmt->execute();
    $result = $stmt->get_result();

    $flats = [];
    while ($row = $result->fetch_assoc()) {
        $flats[] = $row;
    }

    echo json_encode(['success' => true, 'flats' => $flats, 'total' => count($flats)]);
    $stmt->close();
    $conn->close();
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
