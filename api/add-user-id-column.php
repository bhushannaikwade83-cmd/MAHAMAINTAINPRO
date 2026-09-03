<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
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
    // Check if user_id column already exists
    $result = $conn->query("SHOW COLUMNS FROM society_secretaries LIKE 'user_id'");

    if ($result->num_rows === 0) {
        // Add user_id column to society_secretaries table
        $addColumn = "ALTER TABLE society_secretaries ADD COLUMN user_id INT AFTER secretary_id";
        if (!$conn->query($addColumn)) {
            throw new Exception("Failed to add user_id column: " . $conn->error);
        }

        // Add foreign key constraint
        $addFK = "ALTER TABLE society_secretaries ADD CONSTRAINT fk_secretary_user
                  FOREIGN KEY (user_id) REFERENCES individuals(id) ON DELETE CASCADE";

        // Try to add FK, but don't fail if it already exists
        $conn->query($addFK);

        // Create index on user_id for faster lookups
        $addIndex = "CREATE INDEX idx_secretary_user_id ON society_secretaries(user_id)";
        $conn->query($addIndex);

        echo json_encode([
            'success' => true,
            'message' => 'user_id column added to society_secretaries table',
            'columns_added' => ['user_id'],
            'indexes_created' => ['idx_secretary_user_id']
        ]);
    } else {
        echo json_encode([
            'success' => true,
            'message' => 'user_id column already exists',
            'status' => 'already_exists'
        ]);
    }

} catch (Exception $e) {
    http_response_code(500);
    error_log("Migration error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
