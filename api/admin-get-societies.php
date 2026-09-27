<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}


// Admin authentication (real JWT + role check)
require_once 'jwt-auth.php';
requireAdminRole();
try {
    $servername = "localhost";
    $db_username = "digitrix_maha_user";
    $db_password = "maha_user@70";
    $database = "digitrix_maha_maintain_pro";

    $conn = new mysqli($servername, $db_username, $db_password, $database);

    if ($conn->connect_error) {
        throw new Exception("Connection failed: " . $conn->connect_error);
    }

    $query = "SELECT id, name, address, city, postal_code, registration_number, registration_date, contact_phone, contact_email, created_at FROM societies ORDER BY created_at DESC";
    $result = $conn->query($query);

    if (!$result) {
        throw new Exception("Query failed: " . $conn->error);
    }

    $societies = [];
    while ($row = $result->fetch_assoc()) {
        $societies[] = $row;
    }

    echo json_encode(['success' => true, 'societies' => $societies, 'total' => count($societies)]);
    $conn->close();
} catch (Exception $e) {
    http_response_code(500);
    error_log('admin-get-societies error: ' . $e->getMessage() . ' at ' . $e->getFile() . ':' . $e->getLine());
    echo json_encode([
        'success' => false,
        'error' => 'An internal error occurred. Please try again.',
    ]);
}
?>
