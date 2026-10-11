<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Max-Age: 86400');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Database credentials
$servername = "localhost";
$username = "digitrix_maha_user";
$password = "maha_user@70";
$dbname = "digitrix_maha_maintain_pro";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

$conn->set_charset("utf8");

if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    // Get all pending registrations
    $sql = "SELECT
            i.id,
            i.name,
            i.phone,
            i.email,
            i.address,
            i.status,
            i.created_at,
            s.society_name,
            s.society_address,
            s.pincode,
            s.flat_number
            FROM individuals i
            LEFT JOIN societies s ON i.id = s.individual_id
            WHERE i.status = 'pending'
            ORDER BY i.created_at DESC";

    $result = $conn->query($sql);

    if (!$result) {
        http_response_code(500);
        die(json_encode(['success' => false, 'message' => 'Query failed']));
    }

    $registrations = array();
    while ($row = $result->fetch_assoc()) {
        $registrations[] = $row;
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'count' => count($registrations),
        'data' => $registrations
    ]);

} else if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);

    if (!isset($data['individual_id']) || !isset($data['action'])) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Missing required fields']));
    }

    $individual_id = intval($data['individual_id']);
    $action = $conn->real_escape_string($data['action']); // 'approved' or 'rejected'
    $admin_notes = isset($data['admin_notes']) ? $conn->real_escape_string($data['admin_notes']) : '';

    if (!in_array($action, ['approved', 'rejected'])) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Invalid action']));
    }

    // Start transaction
    $conn->begin_transaction();

    try {
        // Update individual status
        $update_sql = "UPDATE individuals SET status = '$action' WHERE id = $individual_id";
        if (!$conn->query($update_sql)) {
            throw new Exception("Error updating individual: " . $conn->error);
        }

        // Insert approval record
        $approval_sql = "INSERT INTO admin_approvals
                        (individual_id, admin_notes, approved_by, approval_date)
                        VALUES ($individual_id, '$admin_notes', 'admin', NOW())";
        if (!$conn->query($approval_sql)) {
            throw new Exception("Error inserting approval record: " . $conn->error);
        }

        // Get individual email for notification
        $email_sql = "SELECT email, name FROM individuals WHERE id = $individual_id";
        $email_result = $conn->query($email_sql);
        $individual = $email_result->fetch_assoc();

        $conn->commit();

        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => "Registration $action successfully",
            'individual_email' => $individual['email'],
            'individual_name' => $individual['name']
        ]);

    } catch (Exception $e) {
        $conn->rollback();
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }

} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}

$conn->close();
?>
