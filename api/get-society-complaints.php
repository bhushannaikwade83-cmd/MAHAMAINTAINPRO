<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Pass either 'mine' (the caller's own complaints, derived from their
// JWT - never a client-supplied user_id) or society_id (committee/
// secretary view of everyone's complaints, membership-checked).
require_once 'jwt-auth.php';

$wantsOwn = isset($_GET['user_id']); // legacy param name, kept for old callers
$society_id = isset($_GET['society_id']) ? (int)$_GET['society_id'] : null;

if (!$wantsOwn && !$society_id) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'user_id or society_id is required']);
    exit;
}

$user_id = null;
if ($wantsOwn) {
    $authToken = verifyJWTToken();
} else {
    requireSocietyMembership($society_id);
}

try {
    $conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');
    if ($conn->connect_error) {
        throw new Exception('Database connection failed');
    }

    // Pull in any vendor-side completion before returning - the vendor app
    // (maha-vendor-app) marks its own `bookings` row COMPLETED when the
    // technician finishes; this is the sync-back point since we don't
    // modify the vendor app's own code to push updates the other way.
    $conn->query("
        UPDATE society_complaints c
        JOIN bookings b ON b.id = c.linked_booking_id
        SET c.status = 'resolved',
            c.resolution_remarks = COALESCE(c.resolution_remarks, 'Marked completed by the assigned vendor'),
            c.resolved_at = COALESCE(b.completed_at, NOW()),
            c.customer_confirmed = 0
        WHERE b.status = 'COMPLETED' AND c.status != 'resolved'
    ");

    // Self-heal: video attachments predate this table's original schema.
    $checkVideoCol = $conn->query("SHOW COLUMNS FROM society_complaints LIKE 'video_url'");
    if ($checkVideoCol->num_rows === 0) {
        $conn->query("ALTER TABLE society_complaints ADD COLUMN video_url VARCHAR(500) NULL");
    }

    $columns = "id, society_id, user_id, flat_id, category, description, priority, photo_url, video_url,
                status, resolution_remarks, resolution_photo_url,
                assigned_vendor_id, assigned_vendor_name, assigned_vendor_phone, customer_confirmed, reopened_count,
                created_at, updated_at, resolved_at";

    if ($wantsOwn) {
        $userStmt = $conn->prepare('SELECT id FROM individuals WHERE phone_number = ?');
        $userStmt->bind_param('s', $authToken['phone_number']);
        $userStmt->execute();
        $userRow = $userStmt->get_result()->fetch_assoc();
        $userStmt->close();
        if (!$userRow) {
            http_response_code(404);
            echo json_encode(['success' => false, 'error' => 'User account not found']);
            exit;
        }
        $user_id = (int)$userRow['id'];

        $stmt = $conn->prepare("SELECT $columns FROM society_complaints WHERE user_id = ? ORDER BY created_at DESC");
        $stmt->bind_param('i', $user_id);
    } else {
        $stmt = $conn->prepare("SELECT $columns FROM society_complaints WHERE society_id = ? ORDER BY created_at DESC");
        $stmt->bind_param('i', $society_id);
    }
    $stmt->execute();
    $result = $stmt->get_result();

    $complaints = [];
    while ($row = $result->fetch_assoc()) {
        $complaints[] = $row;
    }

    echo json_encode(['success' => true, 'complaints' => $complaints, 'total' => count($complaints)]);
    $stmt->close();
    $conn->close();
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
