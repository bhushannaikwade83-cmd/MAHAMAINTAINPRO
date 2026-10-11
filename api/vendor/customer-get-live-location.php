<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

try {
    $pdo = new PDO("mysql:host=localhost;dbname=digitrix_maha_maintain_pro;charset=utf8mb4",
        "digitrix_maha_user", "maha_user@70", [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);

    $request_id = $_GET['request_id'] ?? null;
    if (!$request_id) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'request_id required']);
        exit;
    }

    // Get request details
    $reqStmt = $pdo->prepare("
        SELECT id, latitude, longitude, assigned_vendor_id
        FROM service_requests
        WHERE id = ?
    ");
    $reqStmt->execute([$request_id]);
    $request = $reqStmt->fetch(PDO::FETCH_ASSOC);

    if (!$request) {
        http_response_code(404);
        echo json_encode(['success' => false, 'error' => 'Request not found']);
        exit;
    }

    // Get latest vendor location
    $locStmt = $pdo->prepare("
        SELECT latitude, longitude, speed, accuracy, heading, created_at
        FROM vendor_live_locations
        WHERE request_id = ?
        ORDER BY created_at DESC
        LIMIT 1
    ");
    $locStmt->execute([$request_id]);
    $location = $locStmt->fetch(PDO::FETCH_ASSOC);

    if (!$location) {
        echo json_encode([
            'success' => true,
            'has_location' => false,
            'message' => 'Location tracking not started'
        ]);
        exit;
    }

    // Calculate distance using Haversine formula
    $distance = calculateDistance(
        $request['latitude'],
        $request['longitude'],
        $location['latitude'],
        $location['longitude']
    );

    echo json_encode([
        'success' => true,
        'has_location' => true,
        'vendor_location' => [
            'latitude' => (float)$location['latitude'],
            'longitude' => (float)$location['longitude'],
            'speed' => $location['speed'],
            'accuracy' => $location['accuracy'],
            'heading' => $location['heading']
        ],
        'customer_location' => [
            'latitude' => (float)$request['latitude'],
            'longitude' => (float)$request['longitude']
        ],
        'distance_km' => round($distance, 2),
        'eta_minutes' => ceil(($distance / 20) * 60),
        'last_updated' => $location['created_at']
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}

function calculateDistance($lat1, $lon1, $lat2, $lon2) {
    $R = 6371;
    $dLat = deg2rad($lat2 - $lat1);
    $dLon = deg2rad($lon2 - $lon1);
    $a = sin($dLat/2) * sin($dLat/2) +
         cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
         sin($dLon/2) * sin($dLon/2);
    $c = 2 * atan2(sqrt($a), sqrt(1-$a));
    return $R * $c;
}
?>
