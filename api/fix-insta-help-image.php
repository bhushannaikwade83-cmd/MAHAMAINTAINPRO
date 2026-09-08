<?php
header('Content-Type: application/json');

// One-off fix: "Insta Help" was mistakenly assigned home_services.jpeg
// (which is actually the Hologram Services photo) during an earlier image
// sync. Clears image_path for that category and its services so the app
// falls back to the emoji instead of showing an unrelated photo.
$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);
if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

$conn->begin_transaction();
try {
    $conn->query("UPDATE service_categories SET image_path = NULL WHERE name = 'Insta Help'");
    $categoryRows = $conn->affected_rows;

    $conn->query(
        "UPDATE services s
         JOIN service_categories c ON s.category_id = c.id
         SET s.image_path = NULL
         WHERE c.name = 'Insta Help'"
    );
    $serviceRows = $conn->affected_rows;

    $conn->commit();
    echo json_encode([
        'success' => true,
        'message' => 'Cleared incorrect image_path for Insta Help',
        'category_rows_updated' => $categoryRows,
        'service_rows_updated' => $serviceRows,
    ]);
} catch (Exception $e) {
    $conn->rollback();
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
