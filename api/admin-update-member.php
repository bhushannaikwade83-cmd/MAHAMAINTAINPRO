<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $pdo = new PDO(
        "mysql:host=localhost;dbname=digitrix_maha_maintain_pro;charset=utf8mb4",
        "digitrix_maha_user",
        "maha_user@70",
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    $data = json_decode(file_get_contents('php://input'), true);

    if (!isset($data['id'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Member ID is required']);
        exit;
    }

    $id = $data['id'];
    $updates = [];
    $params = [];

    // Handle is_enabled
    if (isset($data['is_enabled'])) {
        $updates[] = 'is_enabled = ?';
        $params[] = (int)$data['is_enabled'];
    }

    // Handle is_committee
    if (isset($data['is_committee'])) {
        $updates[] = 'is_committee = ?';
        $params[] = (int)$data['is_committee'];

        // If disabling committee (0), auto-set designation to MEMBER
        if ((int)$data['is_committee'] === 0) {
            $updates[] = 'designation = ?';
            $params[] = 'MEMBER';
        }
    }

    // Handle designation (only if is_committee is being enabled or already enabled)
    if (isset($data['designation']) && isset($data['is_committee']) && (int)$data['is_committee'] === 1) {
        // Replace the designation update if it was added for committee
        if (in_array('designation = ?', $updates)) {
            $key = array_search('designation = ?', $updates);
            $params[$key] = $data['designation'];
        } else {
            $updates[] = 'designation = ?';
            $params[] = $data['designation'];
        }
    }

    if (empty($updates)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'No fields to update']);
        exit;
    }

    // Always update the updated_at timestamp
    $updates[] = 'updated_at = NOW()';

    $query = "UPDATE society_customers_individual SET " . implode(', ', $updates) . " WHERE id = ?";
    $params[] = $id;

    $stmt = $pdo->prepare($query);
    $stmt->execute($params);

    if ($stmt->rowCount() === 0) {
        http_response_code(404);
        echo json_encode(['success' => false, 'error' => 'Member not found']);
        exit;
    }

    echo json_encode([
        'success' => true,
        'message' => 'Member updated successfully',
        'id' => $id
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
