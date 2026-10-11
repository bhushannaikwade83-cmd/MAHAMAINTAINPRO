<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Access-Control-Max-Age: 86400');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $filename = $_GET['file'] ?? null;
    error_log("serve-photo.php - Requested file: $filename");

    if (!$filename) {
        http_response_code(400);
        header('Content-Type: application/json');
        echo json_encode(['error' => 'Missing file parameter']);
        exit();
    }

    // Sanitize filename to prevent directory traversal
    $filename = basename($filename);
    error_log("serve-photo.php - Sanitized filename: $filename");

    // Use relative path based on current directory (__DIR__ = api directory)
    $uploadDir = __DIR__ . '/photos/visitor_photos/';
    $filepath = $uploadDir . $filename;

    error_log("serve-photo.php - Full path: $filepath");
    error_log("serve-photo.php - File exists: " . (file_exists($filepath) ? 'yes' : 'no'));
    error_log("serve-photo.php - Is readable: " . (is_readable($filepath) ? 'yes' : 'no'));

    // Check if file exists
    if (!file_exists($filepath)) {
        http_response_code(404);
        header('Content-Type: application/json');
        echo json_encode(['error' => 'File not found: ' . $filepath]);
        error_log("serve-photo.php - File not found: $filepath");
        exit();
    }

    // Get MIME type from file extension (finfo not available on all servers)
    $ext = strtolower(pathinfo($filepath, PATHINFO_EXTENSION));
    $mime = 'image/jpeg'; // Default

    $mimeTypes = [
        'jpg' => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        'bmp' => 'image/bmp'
    ];

    if (isset($mimeTypes[$ext])) {
        $mime = $mimeTypes[$ext];
    }

    error_log("serve-photo.php - MIME type: $mime, File size: " . filesize($filepath));

    header('Content-Type: ' . $mime);
    header('Content-Length: ' . filesize($filepath));
    header('Cache-Control: public, max-age=86400');

    readfile($filepath);
    error_log("serve-photo.php - File served successfully: $filename");

} catch (Exception $e) {
    error_log("serve-photo.php - ERROR: " . $e->getMessage());
    http_response_code(500);
    header('Content-Type: application/json');
    echo json_encode(['error' => $e->getMessage()]);
}
?>
