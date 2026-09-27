<?php
error_reporting(E_ALL);
ini_set('display_errors', 0);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// JWT Authentication (Security Layer)
require_once 'jwt-auth.php';
$token = verifyJWTToken();

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
    $input = json_decode(file_get_contents('php://input'), true);

    // phone_number from verified JWT, not client input
    $phoneNumber = $token['phone_number'];
    $fullAddress = $input['full_address'] ?? null;
    $pincode = $input['pincode'] ?? null;
    $latitude = $input['latitude'] ?? null;
    $longitude = $input['longitude'] ?? null;
    $label = $input['label'] ?? 'Home';
    $addressId = $input['address_id'] ?? null;

    if (!$phoneNumber || !$pincode) {
        throw new Exception('Missing required fields: phone_number, pincode');
    }

    // Verify individual exists
    $checkIndividual = "SELECT id FROM individuals WHERE phone = ?";
    $stmt = $conn->prepare($checkIndividual);
    if (!$stmt) throw new Exception('Prepare failed: ' . $conn->error);
    $stmt->bind_param('s', $phoneNumber);
    $stmt->execute();
    $individualResult = $stmt->get_result();
    $stmt->close();

    if ($individualResult->num_rows === 0) {
        throw new Exception('Individual profile not found. Complete profile first.');
    }

    // Update existing address
    if ($addressId) {
        $updateQuery = "UPDATE addresses SET `full_address`=?, `pincode`=?, `latitude`=?, `longitude`=?, `label`=?, updated_at=NOW() WHERE id=? AND phone_number=?";
        
        $stmt = $conn->prepare($updateQuery);
        if ($stmt === false) {
            throw new Exception("UPDATE Prepare failed: " . $conn->error);
        }
        $stmt->bind_param('ssddsis', $fullAddress, $pincode, $latitude, $longitude, $label, $addressId, $phoneNumber);

        if (!$stmt->execute()) throw new Exception('Update failed: ' . $stmt->error);
        $stmt->close();

        http_response_code(200);
        echo json_encode(['success' => true, 'message' => 'Address updated', 'address_id' => $addressId, 'action' => 'updated']);
    } else {
        // Create new address
        $insertQuery = "INSERT INTO addresses (`phone_number`, `full_address`, `pincode`, `latitude`, `longitude`, `label`) VALUES (?, ?, ?, ?, ?, ?)";
        
        $stmt = $conn->prepare($insertQuery);
        if ($stmt === false) {
            throw new Exception("INSERT Prepare failed: " . $conn->error);
        }
        $stmt->bind_param('sssdds', $phoneNumber, $fullAddress, $pincode, $latitude, $longitude, $label);

        if (!$stmt->execute()) throw new Exception('Insert failed: ' . $stmt->error);
        $newAddressId = $stmt->insert_id;
        $stmt->close();

        // Update address_count
        $updateCount = "UPDATE individuals SET address_count=address_count+1 WHERE phone=?";
        $stmt = $conn->prepare($updateCount);
        if ($stmt) {
            $stmt->bind_param('s', $phoneNumber);
            $stmt->execute();
            $stmt->close();
        }

        http_response_code(200);
        echo json_encode(['success' => true, 'message' => 'Address saved', 'address_id' => $newAddressId, 'action' => 'created']);
    }

} catch (Exception $e) {
    http_response_code(400);
    error_log("Save address error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'An internal error occurred. Please try again.', 'error_type' => 'Exception']);
} catch (Throwable $t) {
    http_response_code(500);
    error_log("Save address fatal error: " . $t->getMessage());
    echo json_encode(['success' => false, 'message' => 'An internal error occurred. Please try again.', 'error_type' => 'Fatal']);
}

if (isset($conn)) {
    $conn->close();
}
?>
