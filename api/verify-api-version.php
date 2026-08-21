<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);

if ($conn->connect_error) {
    echo json_encode(['error' => 'DB connection failed']);
    exit();
}

// Get ONE category with ALL its data
$query = "SELECT id, name, emoji, color, description, image_path FROM service_categories WHERE is_active = 1 LIMIT 1";
$result = $conn->query($query);
$category = $result->fetch_assoc();

// Check what fields are in the SELECT
$allFields = array_keys($category);

echo json_encode([
    'message' => 'API should return these fields:',
    'fields_in_database_query' => $allFields,
    'has_image_path' => in_array('image_path', $allFields) ? '✅ YES' : '❌ NO',
    'sample_category' => $category,
    'note' => in_array('image_path', $allFields)
        ? 'API is querying correctly. Update get-services.php response array.'
        : 'Query is missing image_path SELECT field.'
]);

$conn->close();
?>
