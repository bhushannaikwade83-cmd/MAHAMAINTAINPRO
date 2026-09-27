<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'jwt-auth.php';

$data = json_decode(file_get_contents('php://input'), true);

if (!$data || !isset($data['id']) || !isset($data['society_id']) || (!isset($data['vendor_id']) && !isset($data['vendor_name']))) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'id, society_id and either vendor_id or vendor_name are required']);
    exit;
}

$society_id = (int)$data['society_id'];
requireSocietyManagerRole($society_id);

$id = (int)$data['id'];

try {
    $pdo = new PDO(
        "mysql:host=localhost;dbname=digitrix_maha_maintain_pro;charset=utf8mb4",
        "digitrix_maha_user",
        "maha_user@70",
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    // Prefer a real registered vendor account - look up its name/phone so
    // they stay denormalized on the complaint for display, same as the
    // free-text fallback used to be.
    $vendor_id = null;
    $vendor_name = isset($data['vendor_name']) ? trim($data['vendor_name']) : null;
    $vendor_phone = isset($data['vendor_phone']) ? trim($data['vendor_phone']) : null;

    if (isset($data['vendor_id']) && $data['vendor_id'] !== '') {
        $vendor_id = (int)$data['vendor_id'];
        $vendorStmt = $pdo->prepare('SELECT name, phone FROM vendors WHERE id = ?');
        $vendorStmt->execute([$vendor_id]);
        $vendorRow = $vendorStmt->fetch(PDO::FETCH_ASSOC);
        if (!$vendorRow) {
            http_response_code(404);
            echo json_encode(['success' => false, 'error' => 'Vendor not found']);
            exit;
        }
        $vendor_name = $vendorRow['name'];
        $vendor_phone = $vendorRow['phone'];
    }

    $stmt = $pdo->prepare('
        UPDATE society_complaints
        SET assigned_vendor_id = ?, assigned_vendor_name = ?, assigned_vendor_phone = ?, status = IF(status = "open", "in_progress", status), updated_at = NOW()
        WHERE id = ? AND society_id = ?
    ');
    $stmt->execute([$vendor_id, $vendor_name, $vendor_phone, $id, $society_id]);

    if ($stmt->rowCount() === 0) {
        http_response_code(404);
        echo json_encode(['success' => false, 'error' => 'Complaint not found']);
        exit;
    }

    $bookingId = null;

    // A real registered vendor (not just a free-text note) gets this
    // pushed into the vendor app's own job feed - bookings.vendor_id preset
    // (not NULL) means get-vendor-jobs.php's "my_jobs" query picks it up
    // immediately, without going through the broadcast/accept flow.
    if ($vendor_id) {
        $complaintStmt = $pdo->prepare('SELECT * FROM society_complaints WHERE id = ?');
        $complaintStmt->execute([$id]);
        $complaint = $complaintStmt->fetch(PDO::FETCH_ASSOC);

        $residentName = 'Society Resident';
        $residentPhone = '0000000000';
        if ($complaint['user_id']) {
            $residentStmt = $pdo->prepare('SELECT full_name, phone_number FROM individuals WHERE id = ?');
            $residentStmt->execute([$complaint['user_id']]);
            $residentRow = $residentStmt->fetch(PDO::FETCH_ASSOC);
            if ($residentRow) {
                $residentName = $residentRow['full_name'] ?: $residentName;
                $residentPhone = substr(preg_replace('/\D/', '', $residentRow['phone_number'] ?? ''), -10) ?: $residentPhone;
            }
        }

        $flatLabel = 'Society premises';
        if ($complaint['flat_id']) {
            $flatStmt = $pdo->prepare('SELECT flat_number FROM society_flats WHERE id = ?');
            $flatStmt->execute([$complaint['flat_id']]);
            $flatRow = $flatStmt->fetch(PDO::FETCH_ASSOC);
            if ($flatRow) $flatLabel = 'Flat ' . $flatRow['flat_number'];
        }

        // Society complaints don't map to a real service category - reuse
        // (or create once) a dedicated placeholder category so the FK on
        // bookings.category_id is satisfied.
        $catStmt = $pdo->prepare("SELECT id FROM service_categories WHERE name = 'Society Maintenance' LIMIT 1");
        $catStmt->execute();
        $catRow = $catStmt->fetch(PDO::FETCH_ASSOC);
        if ($catRow) {
            $categoryId = $catRow['id'];
        } else {
            $insertCat = $pdo->prepare("INSERT INTO service_categories (name, description, is_active) VALUES ('Society Maintenance', 'Society complaint jobs assigned to vendors', 1)");
            $insertCat->execute();
            $categoryId = $pdo->lastInsertId();
        }

        if ($complaint['linked_booking_id']) {
            // Already dispatched once - just re-point it at the newly assigned vendor.
            $updateBooking = $pdo->prepare('UPDATE bookings SET vendor_id = ? WHERE id = ?');
            $updateBooking->execute([(string)$vendor_id, $complaint['linked_booking_id']]);
            $bookingId = $complaint['linked_booking_id'];
        } else {
            $insertBooking = $pdo->prepare('
                INSERT INTO bookings (customer_name, customer_phone, category_id, service_type, notes, address, amount, payment_mode, status, vendor_id)
                VALUES (?, ?, ?, ?, ?, ?, 0, "CASH", "REQUESTED", ?)
            ');
            $insertBooking->execute([
                $residentName,
                $residentPhone,
                $categoryId,
                $complaint['category'],
                $complaint['description'],
                $flatLabel,
                (string)$vendor_id,
            ]);
            $bookingId = $pdo->lastInsertId();

            $linkStmt = $pdo->prepare('UPDATE society_complaints SET linked_booking_id = ? WHERE id = ?');
            $linkStmt->execute([$bookingId, $id]);
        }
    }

    echo json_encode([
        'success' => true,
        'message' => 'Vendor assigned successfully',
        'booking_id' => $bookingId,
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
