<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

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
    $vendor_id = $_POST['vendor_id'] ?? null;
    $booking_id = $_POST['booking_id'] ?? null;
    $action = $_POST['action'] ?? null;

    if (!$vendor_id || !$booking_id || !$action) {
        throw new Exception('Missing required: vendor_id, booking_id, action');
    }

    // Verify order belongs to this vendor
    $checkQuery = "SELECT order_id FROM orders WHERE order_id = ? AND vendor_id = ?";
    $checkStmt = $conn->prepare($checkQuery);
    if (!$checkStmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }
    $checkStmt->bind_param("ss", $booking_id, $vendor_id);
    $checkStmt->execute();
    $checkResult = $checkStmt->get_result();
    if ($checkResult->num_rows === 0) {
        throw new Exception("Order not found or not assigned to this vendor");
    }
    $checkStmt->close();

    // Handle based on action
    if ($action === 'start') {
        // Save before photo if provided
        if (isset($_FILES['before_photo'])) {
            $photoDir = __DIR__ . '/photos/job_photos/';
            if (!is_dir($photoDir)) {
                mkdir($photoDir, 0755, true);
            }
            $photoName = $booking_id . '_before_' . time() . '.jpg';
            $photoPath = $photoDir . $photoName;
            if (move_uploaded_file($_FILES['before_photo']['tmp_name'], $photoPath)) {
                $photoUrl = '/mahamaintainpro/api/photos/job_photos/' . $photoName;
                $updateQuery = "UPDATE orders SET before_photo_url = ?, status = 'started' WHERE order_id = ?";
                $updateStmt = $conn->prepare($updateQuery);
                if (!$updateStmt) {
                    throw new Exception("Update failed: " . $conn->error);
                }
                $updateStmt->bind_param("ss", $photoUrl, $booking_id);
                $updateStmt->execute();
                $updateStmt->close();
            }
        }
        $message = 'Job started';

    } elseif ($action === 'complete') {
        // Handle job completion with photos and payment
        $photos = [];

        // Save after photo
        if (isset($_FILES['after_photo'])) {
            $photoDir = __DIR__ . '/photos/job_photos/';
            if (!is_dir($photoDir)) {
                mkdir($photoDir, 0755, true);
            }
            $photoName = $booking_id . '_after_' . time() . '.jpg';
            $photoPath = $photoDir . $photoName;
            if (move_uploaded_file($_FILES['after_photo']['tmp_name'], $photoPath)) {
                $photos['after'] = '/mahamaintainpro/api/photos/job_photos/' . $photoName;
            }
        }

        // Save payment screenshot
        if (isset($_FILES['payment_screenshot'])) {
            $photoDir = __DIR__ . '/photos/payments/';
            if (!is_dir($photoDir)) {
                mkdir($photoDir, 0755, true);
            }
            $photoName = $booking_id . '_payment_' . time() . '.jpg';
            $photoPath = $photoDir . $photoName;
            if (move_uploaded_file($_FILES['payment_screenshot']['tmp_name'], $photoPath)) {
                $photos['payment'] = '/mahamaintainpro/api/photos/payments/' . $photoName;
            }
        }

        // Save customer signature
        if (isset($_FILES['customer_signature'])) {
            $photoDir = __DIR__ . '/photos/signatures/';
            if (!is_dir($photoDir)) {
                mkdir($photoDir, 0755, true);
            }
            $photoName = $booking_id . '_signature_' . time() . '.jpg';
            $photoPath = $photoDir . $photoName;
            if (move_uploaded_file($_FILES['customer_signature']['tmp_name'], $photoPath)) {
                $photos['signature'] = '/mahamaintainpro/api/photos/signatures/' . $photoName;
            }
        }

        // Update order with completion data
        $updateFields = ['status = ?'];
        $params = ['completed'];

        if (!empty($photos['after'])) {
            $updateFields[] = 'after_photo_url = ?';
            $params[] = $photos['after'];
        }
        if (!empty($photos['payment'])) {
            $updateFields[] = 'payment_screenshot_url = ?';
            $params[] = $photos['payment'];
        }
        if (!empty($photos['signature'])) {
            $updateFields[] = 'customer_signature_url = ?';
            $params[] = $photos['signature'];
        }

        if (isset($_POST['completion_otp'])) {
            $updateFields[] = 'completion_otp = ?';
            $params[] = $_POST['completion_otp'];
        }
        if (isset($_POST['work_description'])) {
            $updateFields[] = 'work_description = ?';
            $params[] = $_POST['work_description'];
        }
        if (isset($_POST['parts_used'])) {
            $updateFields[] = 'parts_used = ?';
            $params[] = $_POST['parts_used'];
        }
        if (isset($_POST['additional_charges'])) {
            $updateFields[] = 'additional_charges = ?';
            $params[] = floatval($_POST['additional_charges']);
        }
        if (isset($_POST['technician_remarks'])) {
            $updateFields[] = 'technician_remarks = ?';
            $params[] = $_POST['technician_remarks'];
        }

        $params[] = $booking_id;
        $updateQuery = "UPDATE orders SET " . implode(", ", $updateFields) . ", updated_at = NOW() WHERE order_id = ?";
        $updateStmt = $conn->prepare($updateQuery);
        if (!$updateStmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }

        // Build type string
        $types = str_repeat('s', count($params) - 1) . 's'; // All strings for now
        $updateStmt->bind_param($types, ...$params);
        $updateStmt->execute();
        $updateStmt->close();
        $message = 'Job completed';

    } else {
        throw new Exception('Invalid action');
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => $message,
        'order_id' => $booking_id
    ]);

} catch (Exception $e) {
    http_response_code(400);
    error_log("Update job status error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
