<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit();
}

try {
    // Column layout has drifted from what this file originally assumed
    // (e.g. drop-emoji-column.php removed `emoji` from both tables on the
    // live DB after this query was written) - probe for each optional
    // column instead of assuming it's there, so a schema change doesn't
    // turn into a fatal 500 for the whole endpoint again.
    // $table/$column here are always our own hardcoded constants below,
    // never request input - safe to interpolate directly. (Deliberately
    // NOT a prepared statement: many MySQL/MariaDB versions reject
    // preparing SHOW statements, which fails $conn->prepare() silently
    // returning false and crashes on ->bind_param() with an uncaught
    // Error that a catch(Exception) can't see.)
    $hasColumn = function (string $table, string $column) use ($conn): bool {
        $escapedColumn = $conn->real_escape_string($column);
        $result = $conn->query("SHOW COLUMNS FROM `$table` LIKE '$escapedColumn'");
        return $result !== false && $result->num_rows > 0;
    };

    $categoryHasEmoji = $hasColumn('service_categories', 'emoji');
    $categoryHasImagePath = $hasColumn('service_categories', 'image_path');
    $serviceHasEmoji = $hasColumn('services', 'emoji');
    $serviceHasImagePath = $hasColumn('services', 'image_path');

    $categoryEmojiSelect = $categoryHasEmoji ? 'emoji' : 'NULL as emoji';
    $categoryImageSelect = $categoryHasImagePath ? 'image_path' : 'NULL as image_path';
    $query = "SELECT id, name, $categoryEmojiSelect, color, description, $categoryImageSelect
              FROM service_categories WHERE is_active = 1 ORDER BY id ASC";

    $result = $conn->query($query);

    if (!$result) {
        throw new Exception("Error fetching categories: " . $conn->error);
    }

    $serviceEmojiSelect = $serviceHasEmoji ? 'emoji' : 'NULL as emoji';
    $serviceImageSelect = $serviceHasImagePath ? 'image_path' : 'NULL as image_path';

    $categories = [];
    while ($row = $result->fetch_assoc()) {
        $categoryId = $row['id'];
        error_log("📊 Category: {$row['name']} | image_path: {$row['image_path']}");

        // Fetch services for this category
        $serviceQuery = "SELECT id, name, $serviceEmojiSelect, price, duration, rating, notes, $serviceImageSelect
                          FROM services WHERE category_id = ? AND is_active = 1 ORDER BY id ASC";
        $stmt = $conn->prepare($serviceQuery);
        $stmt->bind_param("i", $categoryId);
        $stmt->execute();
        $serviceResult = $stmt->get_result();

        $services = [];
        while ($serviceRow = $serviceResult->fetch_assoc()) {
            $services[] = $serviceRow;
        }
        $stmt->close();

        $categories[] = [
            'id' => $row['id'],
            'name' => $row['name'],
            'emoji' => $row['emoji'],
            'color' => $row['color'],
            'description' => $row['description'],
            'image_path' => $row['image_path'],
            'services' => $services,
            'service_count' => count($services),
        ];
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'categories' => $categories,
        'total_categories' => count($categories),
        'has_image_support' => $categoryHasImagePath,
    ]);

} catch (Exception $e) {
    http_response_code(500);
    error_log($e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
