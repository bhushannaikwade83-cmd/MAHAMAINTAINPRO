<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    require 'config.php';

    $alertId = $_GET['id'] ?? ($_POST['id'] ?? null);
    $userPhone = $_GET['user_phone'] ?? ($_POST['user_phone'] ?? null);
    $status = $_GET['status'] ?? 'active';

    if ($alertId) {
        // Get specific alert by ID
        $stmt = $pdo->prepare("SELECT * FROM sos_alerts WHERE id = ?");
        $stmt->execute([$alertId]);
        $alert = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$alert) {
            echo json_encode([
                'success' => true,
                'alert' => null,
                'message' => 'Alert not found'
            ]);
            return;
        }

        // Parse JSON fields
        $alert['contacts'] = json_decode($alert['contacts'], true);
        $alert['emergency_fcm_tokens'] = json_decode($alert['emergency_fcm_tokens'], true);

        echo json_encode([
            'success' => true,
            'alert' => $alert
        ]);

    } elseif ($userPhone) {
        // Get all alerts for a specific user
        $stmt = $pdo->prepare("SELECT * FROM sos_alerts WHERE user_phone = ? ORDER BY created_at DESC");
        $stmt->execute([$userPhone]);
        $alerts = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Parse JSON fields
        foreach ($alerts as &$alert) {
            $alert['contacts'] = json_decode($alert['contacts'], true);
            $alert['emergency_fcm_tokens'] = json_decode($alert['emergency_fcm_tokens'], true);
        }

        echo json_encode([
            'success' => true,
            'alerts' => $alerts,
            'total' => count($alerts)
        ]);

    } else {
        // Get all active alerts
        $stmt = $pdo->prepare("SELECT * FROM sos_alerts WHERE status = ? ORDER BY created_at DESC LIMIT 100");
        $stmt->execute([$status]);
        $alerts = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Parse JSON fields
        foreach ($alerts as &$alert) {
            $alert['contacts'] = json_decode($alert['contacts'], true);
            $alert['emergency_fcm_tokens'] = json_decode($alert['emergency_fcm_tokens'], true);
        }

        echo json_encode([
            'success' => true,
            'alerts' => $alerts,
            'total' => count($alerts)
        ]);
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
