<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'DB connection failed: ' . $conn->connect_error]);
    exit();
}

try {
    // Image to category mapping - EXACT MATCH
    $updates = [
        'ac_repair.jpeg' => 'AC & Appliance Repair',
        'blood_testing.jpeg' => 'Blood Testing',
        'car_repair.jpeg' => 'Vehicle Care',
        'cleaning.jpeg' => 'Professional Cleaning',
        'cook.jpeg' => 'Food & Catering',
        'electrician.jpeg' => 'Electrician Plumber Carpenter',
        'festival_services.jpeg' => 'Festival Services',
        'fire_safety.jpeg' => 'Fire Safety',
        'healthcare.jpeg' => 'Health & Care',
        'home_services.jpeg' => 'Insta Help',
        'interior_designer.jpeg' => 'Interior Designer',
        'mens_salon.jpeg' => 'Men\'s Salon & Massage',
        'painting.jpeg' => 'Home Painting',
        'pest_control.jpeg' => 'Pest Control',
        'pooja_services.jpeg' => 'Pooja Services',
        'real_estate.jpeg' => 'Real Estate',
        'smart_society.jpeg' => 'Smart Society Hub',
        'toursandtravels.png' => 'Tours & Travels',
        'water_testing.jpeg' => 'Water Testing',
        'waterproofing.jpeg' => 'Water Proofing',
        'weekly_baxar.jpeg' => 'Weekly Bazar',
        'womens_saloon.jpeg' => 'Women\'s Salon & Spa'
    ];

    // First, get all actual category names from database
    $result = $conn->query("SELECT id, name FROM service_categories WHERE is_active = 1");
    $dbCategories = [];
    while ($row = $result->fetch_assoc()) {
        $dbCategories[$row['name']] = $row['id'];
    }

    echo json_encode([
        'db_categories_found' => count($dbCategories),
        'category_names' => array_keys($dbCategories)
    ]);
    exit();

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
