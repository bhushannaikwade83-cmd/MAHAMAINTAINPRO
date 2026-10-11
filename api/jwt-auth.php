<?php
/**
 * JWT Authentication Middleware
 * Include this in all protected API endpoints
 */

define('JWT_SECRET', getenv('JWT_SECRET') ?: 'your-super-secret-jwt-key-change-in-production');

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
    $expectedSignature = rtrim(strtr(base64_encode(hash_hmac('sha256', "$header.$payload", JWT_SECRET, true)), '+/', '-_'), '=');

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
