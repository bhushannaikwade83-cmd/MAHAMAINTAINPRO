<?php
header('Content-Type: application/json');

$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);

if ($conn->connect_error) {
    die(json_encode(['success' => false, 'message' => 'Connection failed']));
}

// Update all image_path values to use the wrapper
$imageMapping = [
    1 => 'home_services.jpeg',
    2 => 'womens_saloon.jpeg',
    3 => 'mens_salon.jpeg',
    4 => 'cleaning.jpeg',
    5 => 'painting.jpeg',
    6 => 'ac_repair.jpeg',
    7 => 'electrician.jpeg',
    8 => 'car_repair.jpeg',
    9 => 'cook.jpeg',
    10 => 'healthcare.jpeg',
    11 => 'pooja_services.jpeg',
    12 => 'festival_services.jpeg',
    13 => 'pest_control.jpeg',
    14 => 'smart_society.jpeg',
    15 => 'water_testing.jpeg',
    16 => 'blood_testing.jpeg',
    17 => 'weekly_baxar.jpeg',
    18 => 'real_estate.jpeg',
    19 => 'home_services.jpeg',
    20 => 'toursandtravels.png',
];

$updated = 0;

foreach ($imageMapping as $categoryId => $imageName) {
    $wrappedUrl = "https://digitrixmedia.com/mahamaintainpro/api/serve-image.php?name=" . urlencode($imageName);

    $query = "UPDATE service_categories SET image_path = ? WHERE id = ?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("si", $wrappedUrl, $categoryId);

    if ($stmt->execute()) {
        $updated++;
        error_log("✅ Updated category $categoryId with wrapper URL");
    }

    $stmt->close();
}

http_response_code(200);
echo json_encode([
    'success' => true,
    'message' => "Updated $updated categories with CORS-enabled URLs",
    'updated_count' => $updated,
    'example_url' => "https://digitrixmedia.com/mahamaintainpro/api/serve-image.php?name=home_services.jpeg",
]);

$conn->close();
?>
