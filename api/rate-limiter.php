<?php
/**
 * Rate Limiter for OTP and other sensitive endpoints
 */

function checkRateLimit($key, $maxAttempts = 5, $timeWindow = 300) {
    // maxAttempts: max requests allowed
    // timeWindow: seconds (default 5 minutes = 300 seconds)

    $lockFile = sys_get_temp_dir() . '/rate_limit_' . md5($key) . '.json';

    $now = time();
    $attempts = [];

    // Read existing attempts
    if (file_exists($lockFile)) {
        $data = json_decode(file_get_contents($lockFile), true);
        if ($data) {
            // Filter out old attempts outside time window
            $attempts = array_filter($data, function($timestamp) use ($now, $timeWindow) {
                return ($now - $timestamp) < $timeWindow;
            });
        }
    }

    $attemptCount = count($attempts);

    if ($attemptCount >= $maxAttempts) {
        $oldestAttempt = min($attempts);
        $waitTime = $timeWindow - ($now - $oldestAttempt);

        http_response_code(429); // Too Many Requests
        echo json_encode([
            'success' => false,
            'message' => "Too many attempts. Please wait {$waitTime} seconds.",
            'retry_after' => $waitTime
        ]);
        exit();
    }

    // Record this attempt
    $attempts[] = $now;
    file_put_contents($lockFile, json_encode($attempts));
}

function getRemainingAttempts($key, $maxAttempts = 5, $timeWindow = 300) {
    $lockFile = sys_get_temp_dir() . '/rate_limit_' . md5($key) . '.json';
    $now = time();
    $attempts = [];

    if (file_exists($lockFile)) {
        $data = json_decode(file_get_contents($lockFile), true);
        if ($data) {
            $attempts = array_filter($data, function($timestamp) use ($now, $timeWindow) {
                return ($now - $timestamp) < $timeWindow;
            });
        }
    }

    $attemptCount = count($attempts);
    $remaining = max(0, $maxAttempts - $attemptCount);

    if ($attemptCount > 0) {
        $resetTime = min($attempts) + $timeWindow;
        $waitTime = max(0, $resetTime - $now);
    } else {
        $waitTime = 0;
    }

    return [
        'remaining' => $remaining,
        'wait_seconds' => $waitTime
    ];
}
?>
