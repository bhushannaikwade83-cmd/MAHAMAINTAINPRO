<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $pdo = new PDO("mysql:host=localhost;dbname=digitrix_maha_maintain_pro;charset=utf8mb4",
        "digitrix_maha_user", "maha_user@70", [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);

    $data = json_decode(file_get_contents('php://input'), true);

    if (!isset($data['request_id']) || !isset($data['rating'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Missing: request_id, rating']);
        exit;
    }

    if ($data['rating'] < 1 || $data['rating'] > 5) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Rating must be between 1 and 5']);
        exit;
    }

    $pdo->beginTransaction();

    // Update request with rating
    $stmt = $pdo->prepare("
        UPDATE service_requests
        SET rating = ?, review = ?
        WHERE id = ?
    ");

    $stmt->execute([
        $data['rating'],
        $data['review'] ?? '',
        $data['request_id']
    ]);

    // Get vendor ID from request
    $reqStmt = $pdo->prepare("SELECT assigned_vendor_id FROM service_requests WHERE id = ?");
    $reqStmt->execute([$data['request_id']]);
    $request = $reqStmt->fetch(PDO::FETCH_ASSOC);

    if ($request && $request['assigned_vendor_id']) {
        // Update vendor's average rating
        $ratingStmt = $pdo->prepare("
            SELECT AVG(rating) as avg_rating
            FROM service_requests
            WHERE assigned_vendor_id = ? AND rating IS NOT NULL
        ");
        $ratingStmt->execute([$request['assigned_vendor_id']]);
        $ratingData = $ratingStmt->fetch(PDO::FETCH_ASSOC);

        $updateVendor = $pdo->prepare("
            UPDATE vendors
            SET average_rating = ?
            WHERE id = ?
        ");
        $updateVendor->execute([
            round($ratingData['avg_rating'], 1),
            $request['assigned_vendor_id']
        ]);
    }

    $pdo->commit();

    echo json_encode([
        'success' => true,
        'request_id' => $data['request_id'],
        'rating' => (int)$data['rating'],
        'message' => 'Rating submitted successfully'
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
