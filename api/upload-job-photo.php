<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Any logged-in user (vendor uploading job evidence) - not an anonymous caller.
require_once 'jwt-auth.php';
verifyJWTToken();

try {
    $orderId = $_POST['order_id'] ?? null;
    $photoName = $_POST['photo_name'] ?? null;

    if (!$orderId || !isset($_FILES['photo'])) {
        throw new Exception('Missing required fields');
    }

    $file = $_FILES['photo'];
    $fileName = $file['name'];
    $fileTmpName = $file['tmp_name'];
    $fileError = $file['error'];

    if ($fileError !== UPLOAD_ERR_OK) {
        throw new Exception('File upload error: ' . $fileError);
    }

    // Validate file type
    $fileType = mime_content_type($fileTmpName);
    if (!in_array($fileType, ['image/jpeg', 'image/png', 'image/gif'])) {
        throw new Exception('Invalid file type. Only JPEG, PNG, and GIF are allowed.');
    }

    // Create upload directory if not exists
    $uploadDir = __DIR__ . '/../assets/job-photos/';
    if (!is_dir($uploadDir)) {
        mkdir($uploadDir, 0755, true);
    }

    // Generate unique filename
    $newFileName = $orderId . '_' . $photoName . '_' . time() . '.' . pathinfo($fileName, PATHINFO_EXTENSION);
    $uploadPath = $uploadDir . $newFileName;

    // Move uploaded file
    if (!move_uploaded_file($fileTmpName, $uploadPath)) {
        throw new Exception('Failed to save uploaded file');
    }

    $photoUrl = 'https://digitrixmedia.com/mahamaintainpro/assets/job-photos/' . $newFileName;

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Photo uploaded successfully',
        'photo_url' => $photoUrl,
        'photo_name' => $newFileName
    ]);

} catch (Exception $e) {
    http_response_code(400);
    error_log("Upload job photo error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'An internal error occurred. Please try again.']);
}
?>
