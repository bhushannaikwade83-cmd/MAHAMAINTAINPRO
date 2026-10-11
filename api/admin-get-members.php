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
    $conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');

    if ($conn->connect_error) {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => 'Database connection failed']);
        exit;
    }

    $query = "SELECT
        sci.id,
        sci.user_id,
        sci.society_id,
        sci.secretary_name,
        sci.phone,
        sci.is_committee,
        sci.is_enabled,
        sci.designation,
        sci.created_at
    FROM society_customers_individual sci
    ORDER BY sci.created_at DESC";

    $result = $conn->query($query);

    if (!$result) {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => $conn->error]);
        exit;
    }

    $members = [];
    while ($row = $result->fetch_assoc()) {
        $members[] = [
            'id' => $row['id'],
            'user_id' => $row['user_id'],
            'society_id' => $row['society_id'],
            'secretary_name' => $row['secretary_name'],
            'phone' => $row['phone'],
            'is_committee' => (int)$row['is_committee'],
            'is_enabled' => (int)$row['is_enabled'],
            'designation' => $row['designation'],
            'created_at' => $row['created_at']
        ];
    }

    echo json_encode([
        'success' => true,
        'total' => count($members),
        'members' => $members
    ]);

    $conn->close();
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
