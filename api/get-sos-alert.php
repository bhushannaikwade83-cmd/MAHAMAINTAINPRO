<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Any authenticated user can see the active-alerts feed - this is what a
// security guard/committee view polls for incoming emergencies, and this
// codebase has no separate guard-role JWT claim yet to restrict it further
// to (see security_guard_dashboard_screen.dart, which has no role check of
// its own either). "My alerts" is always scoped to the caller's own phone
// from the token, never a client-supplied phone - previously this endpoint
// had no auth at all, so anyone could pull every resident's SOS history,
// live location and emergency contacts by querying with no id/phone.
require_once 'jwt-auth.php';
$authToken = verifyJWTToken();

try {
    require 'config.php';

    $alertId = $_GET['id'] ?? ($_POST['id'] ?? null);
    $wantsOwn = isset($_GET['mine']) || isset($_POST['mine']);
    $userPhone = $wantsOwn ? $authToken['phone_number'] : null;
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
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
