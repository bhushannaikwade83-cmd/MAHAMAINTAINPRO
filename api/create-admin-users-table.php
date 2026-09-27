<?php
/**
 * One-time setup: creates the admin_users table and, if it's empty,
 * seeds a single default super_admin so there's a way to log in at all.
 *
 * Run this once from a browser or curl, then delete it or block it at the
 * webserver level - it's not meant to stay reachable in production.
 */
header('Content-Type: application/json');

$conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');
if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

$createTable = "CREATE TABLE IF NOT EXISTS admin_users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('admin', 'super_admin') NOT NULL DEFAULT 'admin',
    full_name VARCHAR(255),
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)";

if (!$conn->query($createTable)) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Table creation failed: ' . $conn->error]));
}

$countResult = $conn->query("SELECT COUNT(*) AS n FROM admin_users");
$count = $countResult->fetch_assoc()['n'];

$seeded = false;
if ($count == 0) {
    // Default credentials - CHANGE THIS PASSWORD IMMEDIATELY after first login.
    $defaultUsername = 'superadmin';
    $defaultPassword = 'ChangeMe@' . random_int(10000, 99999);
    $hash = password_hash($defaultPassword, PASSWORD_BCRYPT);

    $stmt = $conn->prepare("INSERT INTO admin_users (username, password_hash, role, full_name) VALUES (?, ?, 'super_admin', 'Default Super Admin')");
    $stmt->bind_param('ss', $defaultUsername, $hash);
    $stmt->execute();
    $stmt->close();
    $seeded = true;

    echo json_encode([
        'success' => true,
        'message' => 'admin_users table created and seeded with a default super_admin. SAVE THESE CREDENTIALS NOW and change the password after first login - this response will not be shown again.',
        'username' => $defaultUsername,
        'password' => $defaultPassword,
    ]);
} else {
    echo json_encode([
        'success' => true,
        'message' => 'admin_users table already exists with ' . $count . ' user(s). No changes made.',
    ]);
}

$conn->close();
?>
