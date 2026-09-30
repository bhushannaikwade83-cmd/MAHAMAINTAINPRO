<?php
declare(strict_types=1);

require __DIR__ . '/vendor_config.php';
set_cors_headers();

header('Content-Type: application/json');

require_once __DIR__ . '/jwt-auth.php';

try {
    $vendorToken = requireVendorRole();
    $vendorId = (string) $vendorToken['vendor_id'];

    $input = json_decode((string)file_get_contents('php://input'), true);
    $pincodeId = $input['id'] ?? null;

    if (!$pincodeId) {
        json_response(['error' => 'Pincode ID is required'], 400);
    }

    // Verify this pincode belongs to the vendor
    $checkStmt = db()->prepare(
        'SELECT id FROM vendor_pincodes WHERE id = ? AND vendor_id = ?'
    );
    $checkStmt->execute([$pincodeId, $vendorId]);
    $pincode = $checkStmt->fetch();

    if (!$pincode) {
        http_response_code(403);
        json_response(['success' => false, 'message' => 'Not authorized'], 403);
    }

    // Delete the pincode
    $deleteStmt = db()->prepare('DELETE FROM vendor_pincodes WHERE id = ? AND vendor_id = ?');
    $deleteStmt->execute([$pincodeId, $vendorId]);

    json_response([
        'success' => true,
        'message' => 'Pincode deleted successfully'
    ]);

} catch (Exception $e) {
    http_response_code(500);
    json_response(['success' => false, 'error' => 'Failed to delete pincode: ' . $e->getMessage()]);
}
