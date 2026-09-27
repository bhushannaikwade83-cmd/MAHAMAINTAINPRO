<?php
/**
 * Real file upload for society documents (bylaws, certificates, NOCs etc)
 * - society_documents_screen.dart previously only accepted a URL the user
 * typed in themselves, which meant "uploading" a document required the
 * committee member to already have it hosted somewhere else first.
 * Same upload mechanics as upload-complaint-photo.php / admin-upload-image.php.
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
    $uploadsDir = __DIR__ . '/../assets/society-documents/';
    if (!is_dir($uploadsDir)) {
        mkdir($uploadsDir, 0755, true);
    }

    if (!isset($_FILES['document'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'No document file provided']);
        exit;
    }

    $file = $_FILES['document'];
    $allowedMimes = [
        'application/pdf',
        'image/jpeg',
        'image/png',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    ];
    $maxFileSize = 10 * 1024 * 1024; // 10MB

    if ($file['error'] !== UPLOAD_ERR_OK) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'File upload error: ' . $file['error']]);
        exit;
    }

    $mimeType = mime_content_type($file['tmp_name']);
    if (!in_array($mimeType, $allowedMimes, true)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Invalid file type. Allowed: PDF, JPEG, PNG, DOC, DOCX']);
        exit;
    }

    if ($file['size'] > $maxFileSize) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'File size exceeds 10MB limit']);
        exit;
    }

    $ext = pathinfo($file['name'], PATHINFO_EXTENSION);
    $filename = uniqid('society_doc_') . '.' . $ext;
    $filepath = $uploadsDir . $filename;

    if (!move_uploaded_file($file['tmp_name'], $filepath)) {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => 'Failed to save document']);
        exit;
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Document uploaded successfully',
        'url' => 'https://digitrixmedia.com/mahamaintainpro/assets/society-documents/' . $filename,
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
