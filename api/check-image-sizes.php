<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

try {
    $basePath = __DIR__ . '/../assets/services';

    if (!is_dir($basePath)) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Services folder not found']);
        exit();
    }

    $images = [];
    $stats = [
        'total_images' => 0,
        'total_size_mb' => 0,
        'largest_image' => null,
        'smallest_image' => null,
        'by_category' => []
    ];

    $categories = array_filter(scandir($basePath), function($item) use ($basePath) {
        return is_dir($basePath . '/' . $item) && $item !== '.' && $item !== '..';
    });

    foreach ($categories as $category) {
        $categoryPath = $basePath . '/' . $category;
        $categoryImages = [];
        $categorySize = 0;

        $files = scandir($categoryPath);
        foreach ($files as $file) {
            $filePath = $categoryPath . '/' . $file;
            if (is_file($filePath) && in_array(strtolower(pathinfo($file, PATHINFO_EXTENSION)), ['jpg', 'jpeg', 'png', 'webp'])) {
                $fileSize = filesize($filePath);
                $fileSizeKB = round($fileSize / 1024, 2);

                $categoryImages[] = [
                    'name' => $file,
                    'size_bytes' => $fileSize,
                    'size_kb' => $fileSizeKB,
                    'path' => "assets/services/$category/$file"
                ];

                $categorySize += $fileSize;
                $stats['total_images']++;
                $stats['total_size_mb'] += $fileSize;
            }
        }

        if (!empty($categoryImages)) {
            usort($categoryImages, function($a, $b) {
                return $b['size_bytes'] - $a['size_bytes'];
            });

            $stats['by_category'][] = [
                'category' => $category,
                'image_count' => count($categoryImages),
                'total_size_kb' => round($categorySize / 1024, 2),
                'images' => $categoryImages
            ];
        }
    }

    $stats['total_size_mb'] = round($stats['total_size_mb'] / (1024 * 1024), 2);

    if ($stats['total_images'] > 0) {
        $largestCategory = array_reduce($stats['by_category'], function($carry, $item) {
            if ($carry === null || $item['total_size_kb'] > $carry['total_size_kb']) {
                return $item;
            }
            return $carry;
        });

        $stats['largest_category'] = $largestCategory;
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Image size check complete',
        'stats' => $stats,
        'recommendations' => [
            'Optimal size' => '500x500px or less',
            'Optimal file size' => '50-150KB per image',
            'Format' => 'JPG, PNG, or WebP',
            'Total optimal' => $stats['total_images'] . ' images × 100KB = ' . round($stats['total_images'] * 100 / 1024, 2) . 'MB'
        ]
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
?>
