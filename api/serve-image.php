<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Cache-Control: public, max-age=86400');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$imageName = isset($_GET['name']) ? basename($_GET['name']) : null;

if (!$imageName) {
    http_response_code(400);
    echo json_encode(['error' => 'Image name required']);
    exit();
}

// Whitelist allowed images
$allowedImages = [
    'home_services.jpeg',
    'womens_saloon.jpeg',
    'mens_salon.jpeg',
    'cleaning.jpeg',
    'painting.jpeg',
    'ac_repair.jpeg',
    'electrician.jpeg',
    'car_repair.jpeg',
    'cook.jpeg',
    'healthcare.jpeg',
    'pooja_services.jpeg',
    'festival_services.jpeg',
    'pest_control.jpeg',
    'smart_society.jpeg',
    'water_testing.jpeg',
    'blood_testing.jpeg',
    'weekly_baxar.jpeg',
    'real_estate.jpeg',
    'toursandtravels.png',
];

if (!in_array($imageName, $allowedImages)) {
    http_response_code(404);
    echo json_encode(['error' => 'Image not found']);
    exit();
}

$imagePath = __DIR__ . '/../assets/services/' . $imageName;

if (!file_exists($imagePath)) {
    http_response_code(404);
    echo json_encode(['error' => 'Image file not found']);
    exit();
}

// Determine mime type
$mimeTypes = [
    'jpeg' => 'image/jpeg',
    'jpg' => 'image/jpeg',
    'png' => 'image/png',
    'gif' => 'image/gif',
];

$ext = strtolower(pathinfo($imageName, PATHINFO_EXTENSION));
$mimeType = $mimeTypes[$ext] ?? 'image/jpeg';

// Set cache headers
$file_mtime = filemtime($imagePath);
$etag = '"' . md5_file($imagePath) . '"';

header('Content-Type: ' . $mimeType);
header('Content-Length: ' . filesize($imagePath));
header('Cache-Control: public, max-age=31536000, immutable'); // 1 year - static files
header('Last-Modified: ' . gmdate('r', $file_mtime));
header('ETag: ' . $etag);
header('Expires: ' . gmdate('r', time() + 31536000));

// Check If-None-Match for ETag
if (isset($_SERVER['HTTP_IF_NONE_MATCH']) && $_SERVER['HTTP_IF_NONE_MATCH'] === $etag) {
    http_response_code(304);
    exit();
}

// Check If-Modified-Since
if (isset($_SERVER['HTTP_IF_MODIFIED_SINCE'])) {
    if (strtotime($_SERVER['HTTP_IF_MODIFIED_SINCE']) >= $file_mtime) {
        http_response_code(304);
        exit();
    }
}

readfile($imagePath);
exit();
?>
