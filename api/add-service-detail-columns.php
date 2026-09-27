<?php
/**
 * One-time migration: adds description/inclusions/exclusions/warranty
 * columns to the services table for the service detail screen, and backfills
 * any NULL rows with a generic, honest default (no fabricated stats).
 * Run once, then delete or block this file.
 */
header('Content-Type: application/json');

$conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');
if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

// Add each column only if it doesn't already exist - checked via
// INFORMATION_SCHEMA rather than "ADD COLUMN IF NOT EXISTS" since that
// syntax needs MySQL 8.0.29+ / MariaDB 10.0+, which shared hosting may not have.
function addColumnIfMissing(mysqli $conn, string $table, string $column, string $definition): ?string {
    $check = $conn->prepare(
        "SELECT COUNT(*) AS n FROM information_schema.columns
         WHERE table_schema = DATABASE() AND table_name = ? AND column_name = ?"
    );
    $check->bind_param('ss', $table, $column);
    $check->execute();
    $exists = (int) $check->get_result()->fetch_assoc()['n'] > 0;
    $check->close();

    if ($exists) {
        return null;
    }

    if (!$conn->query("ALTER TABLE `$table` ADD COLUMN `$column` $definition")) {
        return $conn->error;
    }
    return null;
}

$errors = [];
foreach ([
    ['services', 'description', 'TEXT NULL'],
    ['services', 'whats_included', 'TEXT NULL'],
    ['services', 'whats_not_included', 'TEXT NULL'],
    ['services', 'warranty_text', 'VARCHAR(255) NULL'],
    ['service_categories', 'faqs', 'TEXT NULL'],
] as [$table, $column, $definition]) {
    $error = addColumnIfMissing($conn, $table, $column, $definition);
    if ($error !== null) {
        $errors[] = "$table.$column: $error";
    }
}

// Backfill generic, non-fabricated defaults where empty. This is boilerplate
// policy text, not a specific factual claim about any one service, so it's
// safe to default - edit per-service later via the services table directly
// (or the admin panel, once built) for anything that needs to be more specific.
$conn->query("UPDATE services SET description = CONCAT(name, ' performed by a verified professional.') WHERE description IS NULL OR description = ''");
$conn->query("UPDATE services SET whats_included = 'Professional labor\nStandard tools and equipment\nBasic consumables for the job' WHERE whats_included IS NULL OR whats_included = ''");
$conn->query("UPDATE services SET whats_not_included = 'Cost of spare parts or replacement materials, if required\nAny additional work outside the described scope' WHERE whats_not_included IS NULL OR whats_not_included = ''");
$conn->query("UPDATE services SET warranty_text = '7-day service guarantee' WHERE warranty_text IS NULL OR warranty_text = ''");

// Category-level FAQs (generic, applies to any service)
$defaultFaqs = json_encode([
    ['q' => 'How do I reschedule or cancel my booking?', 'a' => 'Go to My Bookings, open the order, and use the reschedule or cancel option before the technician is assigned.'],
    ['q' => 'What if I\'m not satisfied with the service?', 'a' => 'Contact Help & Support within 24 hours of service completion and we\'ll arrange a resolution as per the service guarantee.'],
    ['q' => 'Do I need to arrange any materials myself?', 'a' => 'Standard tools and basic consumables are included. Spare parts or special materials, if needed, are billed separately with your approval.'],
]);
$stmt = $conn->prepare("UPDATE service_categories SET faqs = ? WHERE faqs IS NULL OR faqs = ''");
$stmt->bind_param('s', $defaultFaqs);
$stmt->execute();
$stmt->close();

http_response_code(200);
echo json_encode([
    'success' => empty($errors),
    'message' => empty($errors) ? 'Migration complete' : 'Completed with some errors',
    'errors' => $errors,
]);

$conn->close();
?>
