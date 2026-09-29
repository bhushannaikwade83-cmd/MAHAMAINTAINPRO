<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Get phone number from JWT OR from query parameter (fallback for mobile app)
$phone_number = null;

// Try JWT first
require_once 'jwt-auth.php';
try {
    $token = verifyJWTToken();
    $phone_number = $token['phone_number'] ?? null;
    error_log("✅ [get-addresses] JWT verified for phone: " . $phone_number);
} catch (Exception $e) {
    error_log("⚠️ [get-addresses] JWT verification failed: " . $e->getMessage());
    // Fall back to query parameter
    $phone_number = $_GET['phone_number'] ?? null;
    if ($phone_number) {
        error_log("✅ [get-addresses] Using phone from query parameter: " . $phone_number);
    }
}

if (!$phone_number) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Phone number required']);
    exit();
}

// Database connection
$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit();
}

try {
    error_log("🔍 [get-addresses] Fetching addresses for phone: " . $phone_number);

    // Fetch this user's addresses only
    $query = "SELECT id, full_address, pincode, latitude, longitude, label, created_at
              FROM addresses WHERE phone_number = ? ORDER BY created_at DESC LIMIT 10";

    $stmt = $conn->prepare($query);
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }

    $stmt->bind_param("s", $phone_number);

    if (!$stmt->execute()) {
        throw new Exception("Execute failed: " . $stmt->error);
    }

    $result = $stmt->get_result();

    $addresses = [];
    while ($row = $result->fetch_assoc()) {
        $addresses[] = $row;
    }

    $stmt->close();

    error_log("✅ [get-addresses] Found " . count($addresses) . " addresses for phone: " . $phone_number);

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'addresses' => $addresses,
        'count' => count($addresses)
    ]);

} catch (Exception $e) {
    error_log("❌ [get-addresses] Error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'An internal error occurred. Please try again.',
        'error_debug' => $e->getMessage()
    ]);
}

$conn->close();
?>
