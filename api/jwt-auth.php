<?php
/**
 * JWT Authentication Middleware
 * Include this in all protected API endpoints
 */

// The signing key is read from jwt_secret.txt, one level above public_html
// (api/ sits in public_html/mahamaintainpro/api), so it is never served to
// visitors. There is deliberately no default: a public fallback would let
// anyone forge a token.
function jwtSecret() {
    $file = dirname(__DIR__, 3) . '/jwt_secret.txt';
    $secret = is_readable($file) ? trim((string) file_get_contents($file)) : '';
    if (strlen($secret) < 32) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Server authentication is not configured']);
        exit();
    }
    return $secret;
}

// Issues a signed token. Only call this after OTP or M-PIN verification.
function generateJWT(array $claims, int $ttlSeconds = 86400) {
    $now = time();
    $header = rtrim(strtr(base64_encode(json_encode(['alg' => 'HS256', 'typ' => 'JWT'])), '+/', '-_'), '=');
    $payload = rtrim(strtr(base64_encode(json_encode($claims + ['iat' => $now, 'exp' => $now + $ttlSeconds])), '+/', '-_'), '=');
    $signature = rtrim(strtr(base64_encode(hash_hmac('sha256', "$header.$payload", jwtSecret(), true)), '+/', '-_'), '=');
    return "$header.$payload.$signature";
}

function verifyJWTToken() {
    // Get token from Authorization header
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? null;

    if (!$authHeader) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Missing authorization token']);
        exit();
    }

    // Extract token from "Bearer <token>"
    if (!preg_match('/Bearer\s+(.+)/', $authHeader, $matches)) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Invalid authorization format']);
        exit();
    }

    $token = $matches[1];

    // Verify JWT
    $parts = explode('.', $token);
    if (count($parts) !== 3) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Invalid token format']);
        exit();
    }

    list($header, $payload, $signature) = $parts;

    // Verify signature
    $expectedSignature = rtrim(strtr(base64_encode(hash_hmac('sha256', "$header.$payload", jwtSecret(), true)), '+/', '-_'), '=');

    if ($signature !== $expectedSignature) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Invalid token signature']);
        exit();
    }

    // Decode and verify expiry
    $decoded = json_decode(base64_decode(strtr($payload, '-_', '+/')), true);

    if (!$decoded) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Invalid token data']);
        exit();
    }

    if ($decoded['exp'] < time()) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Token has expired']);
        exit();
    }

    return $decoded; // Return decoded token with phone_number
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
