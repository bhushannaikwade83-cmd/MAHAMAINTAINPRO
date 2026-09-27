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

// Self-heal: ensure the service-detail columns exist (same pattern this
// codebase already uses for "CREATE TABLE IF NOT EXISTS" elsewhere), so this
// endpoint works even if add-service-detail-columns.php hasn't been run yet.
function ensureColumn(mysqli $conn, string $table, string $column, string $definition): void {
    $check = $conn->prepare(
        "SELECT COUNT(*) AS n FROM information_schema.columns
         WHERE table_schema = DATABASE() AND table_name = ? AND column_name = ?"
    );
    $check->bind_param('ss', $table, $column);
    $check->execute();
    $exists = (int) $check->get_result()->fetch_assoc()['n'] > 0;
    $check->close();
    if (!$exists) {
        $conn->query("ALTER TABLE `$table` ADD COLUMN `$column` $definition");
    }
}
ensureColumn($conn, 'services', 'description', 'TEXT NULL');
ensureColumn($conn, 'services', 'whats_included', 'TEXT NULL');
ensureColumn($conn, 'services', 'whats_not_included', 'TEXT NULL');
ensureColumn($conn, 'services', 'warranty_text', 'VARCHAR(255) NULL');
ensureColumn($conn, 'service_categories', 'faqs', 'TEXT NULL');

try {
    // Get all categories with color and image
    $query = "SELECT id, name, description, color, image_path, faqs FROM service_categories WHERE is_active = 1 ORDER BY id ASC";
    $result = $conn->query($query);

    if (!$result) {
        throw new Exception("Error fetching categories: " . $conn->error);
    }

    $categories = [];
    while ($row = $result->fetch_assoc()) {
        $categoryId = $row['id'];

        // Fetch services for this category
        $serviceQuery = "SELECT id, name, price, duration, description, whats_included, whats_not_included, warranty_text FROM services WHERE category_id = ? AND is_active = 1 ORDER BY id ASC";
        $stmt = $conn->prepare($serviceQuery);
        $stmt->bind_param("i", $categoryId);
        $stmt->execute();
        $serviceResult = $stmt->get_result();

        $services = [];
        while ($serviceRow = $serviceResult->fetch_assoc()) {
            if (empty($serviceRow['description'])) {
                $serviceRow['description'] = $serviceRow['name'] . ' performed by a verified professional.';
            }
            if (empty($serviceRow['whats_included'])) {
                $serviceRow['whats_included'] = "Professional labor\nStandard tools and equipment\nBasic consumables for the job";
            }
            if (empty($serviceRow['whats_not_included'])) {
                $serviceRow['whats_not_included'] = "Cost of spare parts or replacement materials, if required\nAny additional work outside the described scope";
            }
            if (empty($serviceRow['warranty_text'])) {
                $serviceRow['warranty_text'] = '7-day service guarantee';
            }
            $services[] = $serviceRow;
        }
        $stmt->close();

        // Construct full image URL (images stored in /assets/services/)
        $imageUrl = !empty($row['image_path'])
            ? 'https://digitrixmedia.com/mahamaintainpro/assets/services/' . $row['image_path']
            : null;

        $defaultFaqs = [
            ['q' => 'How do I reschedule or cancel my booking?', 'a' => 'Go to My Bookings, open the order, and use the reschedule or cancel option before the technician is assigned.'],
            ['q' => "What if I'm not satisfied with the service?", 'a' => "Contact Help & Support within 24 hours of service completion and we'll arrange a resolution as per the service guarantee."],
            ['q' => 'Do I need to arrange any materials myself?', 'a' => 'Standard tools and basic consumables are included. Spare parts or special materials, if needed, are billed separately with your approval.'],
        ];
        $faqs = !empty($row['faqs']) ? json_decode($row['faqs'], true) : null;
        if (!is_array($faqs)) {
            $faqs = $defaultFaqs;
        }

        $categories[] = [
            'id' => $row['id'],
            'name' => $row['name'],
            'description' => $row['description'],
            'color' => $row['color'],
            'image_path' => $imageUrl,
            'services' => $services,
            'service_count' => count($services),
            'faqs' => $faqs,
        ];
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'categories' => $categories,
        'total_categories' => count($categories),
    ]);

} catch (Exception $e) {
    http_response_code(500);
    error_log($e->getMessage());
    echo json_encode(['success' => false, 'message' => 'An internal error occurred. Please try again.']);
}

$conn->close();
?>
