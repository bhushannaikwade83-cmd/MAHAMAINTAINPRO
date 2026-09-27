<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Any logged-in resident/secretary/admin can attach a complaint photo -
// either the initial evidence or the committee's before/after resolution
// evidence. Same upload mechanics as admin-upload-image.php.
require_once 'jwt-auth.php';
verifyJWTToken();

try {
    $uploadsDir = __DIR__ . '/../assets/complaints/';
    if (!is_dir($uploadsDir)) {
        mkdir($uploadsDir, 0755, true);
    }

    if (!isset($_FILES['image'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'No image file provided']);
        exit;
    }

    $file = $_FILES['image'];
    $allowedMimes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    $maxFileSize = 5 * 1024 * 1024; // 5MB

    if ($file['error'] !== UPLOAD_ERR_OK) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'File upload error: ' . $file['error']]);
        exit;
    }

    if (!in_array($file['type'], $allowedMimes)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Invalid image format. Allowed: JPEG, PNG, GIF, WebP']);
        exit;
    }

    if ($file['size'] > $maxFileSize) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'File size exceeds 5MB limit']);
        exit;
    }

    $ext = pathinfo($file['name'], PATHINFO_EXTENSION);
    $filename = uniqid('complaint_') . '.' . $ext;
    $filepath = $uploadsDir . $filename;

    if (!move_uploaded_file($file['tmp_name'], $filepath)) {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => 'Failed to save image']);
        exit;
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Image uploaded successfully',
        'url' => 'https://digitrixmedia.com/mahamaintainpro/assets/complaints/' . $filename,
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
