<?php
header('Content-Type: application/json');

$apiFiles = [
    'get-customer-orders.php' => file_get_contents(__DIR__ . '/get-customer-orders.php'),
    'send-otp.php' => file_get_contents(__DIR__ . '/send-otp.php'),
];

$versions = [];

foreach ($apiFiles as $filename => $content) {
    $hasDebugLogging = strpos($content, 'error_log') !== false;
    $hasAutoCreate = strpos($content, 'CREATE TABLE') !== false;
    $has4DigitOtp = preg_match('/random_int\(0, 9999\)/', $content);

    $versions[$filename] = [
        'file_exists' => true,
        'size' => strlen($content),
        'has_debug_logging' => $hasDebugLogging,
        'has_auto_create_table' => $hasAutoCreate,
        'has_4_digit_otp' => (bool)$has4DigitOtp,
        'last_modified' => date('Y-m-d H:i:s', filemtime(__DIR__ . '/' . $filename))
    ];
}

// Test get-customer-orders.php
$testPhone = '7738233032';
$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);
if (!$conn->connect_error) {
    $query = "SELECT COUNT(*) as count FROM orders WHERE phone_number = '$testPhone'";
    $result = $conn->query($query);
    if ($result) {
        $row = $result->fetch_assoc();
        $versions['database_test'] = [
            'phone' => $testPhone,
            'orders_found' => $row['count']
        ];
    }
    $conn->close();
}

echo json_encode($versions, JSON_PRETTY_PRINT);
?>
