<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

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

    $phoneNumber = $input['phone_number'] ?? null;
    $fullName = $input['full_name'] ?? null;
    $email = $input['email'] ?? null;

    if (!$phoneNumber || !$fullName || !$email) {
        throw new Exception('Missing required fields: phone_number, full_name, email');
    }

    // Validate email format
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        throw new Exception('Invalid email format');
    }

    // Create individuals table if not exists
    $createTable = "CREATE TABLE IF NOT EXISTS individuals (
        id INT AUTO_INCREMENT PRIMARY KEY,
        phone_number VARCHAR(20) UNIQUE NOT NULL,
        full_name VARCHAR(255) NOT NULL,
        email VARCHAR(255),
        profile_picture_url VARCHAR(500),
        role VARCHAR(50) DEFAULT 'individual',
        address_count INT DEFAULT 0,
        is_active BOOLEAN DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY unique_phone (phone_number),
        UNIQUE KEY unique_email (email)
    )";

    if (!$conn->query($createTable)) {
        throw new Exception("Table creation failed: " . $conn->error);
    }

    // Note: Table already has 'phone' column - no need to add

    // Check if individual already exists - use correct "phone" column
    $checkQuery = "SELECT id FROM individuals WHERE phone = ?";
    $stmt = $conn->prepare($checkQuery);
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }
    $stmt->bind_param('s', $phoneNumber);
    $stmt->execute();
    $checkResult = $stmt->get_result();
    $stmt->close();

    if ($checkResult->num_rows > 0) {
        // Update existing individual
        $updateQuery = "UPDATE individuals SET full_name = ?, email = ?, updated_at = NOW() WHERE phone = ?";
        $stmt = $conn->prepare($updateQuery);
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        $stmt->bind_param('sss', $fullName, $email, $phoneNumber);

        if (!$stmt->execute()) {
            throw new Exception("Update failed: " . $stmt->error);
        }
        $stmt->close();

        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Profile updated successfully',
            'phone_number' => $phoneNumber,
            'action' => 'updated',
        ]);
    } else {
        // Create new individual - use correct column names
        $insertQuery = "INSERT INTO individuals (phone, full_name, email, name, status)
                        VALUES (?, ?, ?, ?, 'active')";
        $stmt = $conn->prepare($insertQuery);
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        $stmt->bind_param('ssss', $phoneNumber, $fullName, $email, $fullName);

        if (!$stmt->execute()) {
            // Check if it's a duplicate email error
            if (strpos($stmt->error, 'Duplicate entry') !== false && strpos($stmt->error, 'unique_email') !== false) {
                throw new Exception('Email already registered with another phone number');
            }
            throw new Exception("Insert failed: " . $stmt->error);
        }
        $stmt->close();

        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Profile created successfully',
            'phone_number' => $phoneNumber,
            'action' => 'created',
        ]);
    }

} catch (Exception $e) {
    http_response_code(400);
    error_log("Create individual error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'An internal error occurred. Please try again.']);
}

$conn->close();
?>
