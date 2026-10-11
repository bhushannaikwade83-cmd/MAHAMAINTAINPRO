<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

echo json_encode([
    'success' => true,
    'message' => 'API is working',
    'timestamp' => date('Y-m-d H:i:s'),
    'dir' => __DIR__,
    'server' => $_SERVER['HTTP_HOST'] ?? 'unknown'
]);
?>
