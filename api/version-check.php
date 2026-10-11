<?php
header('Content-Type: application/json');

$file = __FILE__;
$content = file_get_contents(__FILE__);

// Check which version of get-customer-orders.php is on server
$getOrdersFile = dirname(__FILE__) . '/get-customer-orders.php';
$getOrdersContent = file_get_contents($getOrdersFile);

$hasRatingsTable = strpos($getOrdersContent, 'ratings') !== false;
$hasAutoCreate = strpos($getOrdersContent, 'CREATE TABLE IF NOT EXISTS') !== false;

echo json_encode([
    'status' => 'API Version Check',
    'get_customer_orders_file_exists' => file_exists($getOrdersFile),
    'file_size' => filesize($getOrdersFile),
    'file_modified' => date('Y-m-d H:i:s', filemtime($getOrdersFile)),
    'contains_ratings_table_reference' => $hasRatingsTable,
    'contains_auto_create' => $hasAutoCreate,
    'needs_update' => $hasRatingsTable ? true : false,
    'message' => $hasRatingsTable ? '❌ OLD VERSION - Still has ratings table' : '✅ NEW VERSION - Ratings removed',
], JSON_PRETTY_PRINT);
?>
