<?php
/**
 * Session tokens for the app and the admin panel.
 *
 * Login (OTP or M-PIN) creates a random token and stores only its SHA-256 hash
 * in the app_sessions table. Protected endpoints call verifyJWTToken(), which
 * looks the token up there. No signing secret is used.
 *
 * Table: database/migrations/003_create_app_sessions.sql
 */
require_once __DIR__ . '/config.php';

define('SESSION_TTL_SECONDS', 86400); // 24 hours

// Stores a new session and returns its token. Throws if the table is missing.
function createSession(array $claims) {
    global $pdo;
    $token = bin2hex(random_bytes(32));
    $stmt = $pdo->prepare(
        'INSERT INTO app_sessions (token_hash, phone_number, role, expires_at) VALUES (?, ?, ?, ?)'
    );
    $stmt->execute([
        hash('sha256', $token),
        $claims['phone_number'] ?? null,
        $claims['role'] ?? null,
        date('Y-m-d H:i:s', time() + SESSION_TTL_SECONDS),
    ]);
    return $token;
}

// Used by OTP and M-PIN login. Returns null if the session cannot be stored,
// so the login itself still succeeds.
function tryGenerateJWT(array $claims) {
    try {
        return createSession($claims);
    } catch (Throwable $e) {
        error_log('Session not created: ' . $e->getMessage());
        return null;
    }
}

// Used by admin login. Throws if the session cannot be stored.
function generateJWT(array $claims) {
    return createSession($claims);
}

function verifyJWTToken() {
    global $pdo;

    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? null;

    if (!$authHeader) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Missing authorization token']);
        exit();
    }

    if (!preg_match('/Bearer\s+([a-f0-9]{64})/', $authHeader, $matches)) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Invalid authorization format']);
        exit();
    }

    $stmt = $pdo->prepare(
        'SELECT phone_number, role FROM app_sessions WHERE token_hash = ? AND expires_at > ? LIMIT 1'
    );
    $stmt->execute([hash('sha256', $matches[1]), date('Y-m-d H:i:s')]);
    $session = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$session) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Invalid or expired token']);
        exit();
    }

    return ['phone_number' => $session['phone_number'], 'role' => $session['role']];
}

function requireAdminRole() {
    $token = verifyJWTToken();

    if (!isset($token['role']) || $token['role'] !== 'admin') {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Admin access required']);
        exit();
    }

    return $token;
}

function requireVendorRole() {
    $token = verifyJWTToken();

    if (!isset($token['role']) || $token['role'] !== 'vendor') {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Vendor access required']);
        exit();
    }

    return $token;
}
?>
