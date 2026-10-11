<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Access-Control-Max-Age: 86400');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$filename = $_GET['file'] ?? null;

if (!$filename) {
    http_response_code(400);
    echo json_encode(['error' => 'Missing file parameter']);
    exit();
}

// Sanitize filename to prevent directory traversal
$filename = basename($filename);

$filepath = __DIR__ . '/photos/visitor_photos/' . $filename;

// Check if file exists and is in the correct directory
if (!file_exists($filepath) || strpos(realpath($filepath), realpath(__DIR__ . '/photos/visitor_photos/')) !== 0) {
    http_response_code(404);
    echo json_encode(['error' => 'File not found']);
    exit();
}

// Get MIME type
$finfo = finfo_open(FILEINFO_MIME_TYPE);
$mime = finfo_file($finfo, $filepath);
finfo_close($finfo);

header('Content-Type: ' . $mime);
header('Content-Length: ' . filesize($filepath));
header('Cache-Control: public, max-age=86400');

readfile($filepath);
?>
