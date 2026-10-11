<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

echo json_encode([
    'dir' => __DIR__,
    'file' => __FILE__,
    'realpath' => realpath(__DIR__),
    'photos_dir' => __DIR__ . '/photos/visitor_photos/',
    'photos_dir_exists' => is_dir(__DIR__ . '/photos/visitor_photos/') ? 'yes' : 'no',
    'photos_dir_writable' => is_writable(__DIR__ . '/photos/') ? 'yes' : 'no',
    'server_host' => $_SERVER['HTTP_HOST'] ?? 'unknown',
    'php_version' => phpversion()
], JSON_PRETTY_PRINT);
?>
