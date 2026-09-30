<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

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
    $vendor_id = $_GET['vendor_id'] ?? null;

    if (!$vendor_id) {
        throw new Exception('Vendor ID is required');
    }

    // Get vendor ratings summary
    $summaryQuery = "
        SELECT
            COUNT(*) as total_ratings,
            ROUND(AVG(rating), 1) as avg_rating,
            SUM(CASE WHEN rating = 5 THEN 1 ELSE 0 END) as five_star,
            SUM(CASE WHEN rating = 4 THEN 1 ELSE 0 END) as four_star,
            SUM(CASE WHEN rating = 3 THEN 1 ELSE 0 END) as three_star,
            SUM(CASE WHEN rating = 2 THEN 1 ELSE 0 END) as two_star,
            SUM(CASE WHEN rating = 1 THEN 1 ELSE 0 END) as one_star
        FROM ratings
        WHERE vendor_id = ?
    ";

    $summaryStmt = $conn->prepare($summaryQuery);
    if (!$summaryStmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }

    $summaryStmt->bind_param('i', $vendor_id);
    $summaryStmt->execute();
    $summaryResult = $summaryStmt->get_result();
    $summary = $summaryResult->fetch_assoc();
    $summaryStmt->close();

    // Get recent ratings
    $recentQuery = "
        SELECT
            r.rating,
            r.comment,
            r.created_at,
            o.order_id,
            GROUP_CONCAT(oi.service_name SEPARATOR ', ') as services
        FROM ratings r
        JOIN orders o ON r.order_id = o.order_id
        LEFT JOIN order_items oi ON o.order_id = oi.order_id
        WHERE r.vendor_id = ?
        GROUP BY r.order_id
        ORDER BY r.created_at DESC
        LIMIT 20
    ";

    $recentStmt = $conn->prepare($recentQuery);
    if (!$recentStmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }

    $recentStmt->bind_param('i', $vendor_id);
    $recentStmt->execute();
    $recentResult = $recentStmt->get_result();

    $ratings = [];
    while ($row = $recentResult->fetch_assoc()) {
        $ratings[] = [
            'order_id' => $row['order_id'],
            'rating' => (int)$row['rating'],
            'comment' => $row['comment'],
            'services' => $row['services'],
            'date' => $row['created_at'],
        ];
    }
    $recentStmt->close();

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'vendor_id' => (int)$vendor_id,
        'summary' => [
            'total_ratings' => (int)($summary['total_ratings'] ?? 0),
            'avg_rating' => (float)($summary['avg_rating'] ?? 0),
            'breakdown' => [
                '5_star' => (int)($summary['five_star'] ?? 0),
                '4_star' => (int)($summary['four_star'] ?? 0),
                '3_star' => (int)($summary['three_star'] ?? 0),
                '2_star' => (int)($summary['two_star'] ?? 0),
                '1_star' => (int)($summary['one_star'] ?? 0),
            ],
        ],
        'recent_ratings' => $ratings,
    ]);

} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}

$conn->close();
?>
