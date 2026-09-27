<?php
/**
 * Video attachment for complaints - mirrors upload-complaint-photo.php's
 * mechanics but for video evidence, which wasn't supported before (photo
 * only).
 */
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'jwt-auth.php';
verifyJWTToken();

try {
    $uploadsDir = __DIR__ . '/../assets/complaints/';
    if (!is_dir($uploadsDir)) {
        mkdir($uploadsDir, 0755, true);
    }

    if (!isset($_FILES['video'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'No video file provided']);
        exit;
    }

    $file = $_FILES['video'];
    $allowedMimes = ['video/mp4', 'video/quicktime', 'video/3gpp', 'video/x-matroska'];
    $maxFileSize = 30 * 1024 * 1024; // 30MB - enough for a short clip, not a movie

    if ($file['error'] !== UPLOAD_ERR_OK) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'File upload error: ' . $file['error']]);
        exit;
    }

    $mimeType = mime_content_type($file['tmp_name']);
    if (!in_array($mimeType, $allowedMimes, true)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Invalid video format. Allowed: MP4, MOV, 3GP, MKV']);
        exit;
    }

    if ($file['size'] > $maxFileSize) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'File size exceeds 30MB limit']);
        exit;
    }

    $ext = pathinfo($file['name'], PATHINFO_EXTENSION) ?: 'mp4';
    $filename = uniqid('complaint_video_') . '.' . $ext;
    $filepath = $uploadsDir . $filename;

    if (!move_uploaded_file($file['tmp_name'], $filepath)) {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => 'Failed to save video']);
        exit;
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Video uploaded successfully',
        'url' => 'https://digitrixmedia.com/mahamaintainpro/assets/complaints/' . $filename,
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
