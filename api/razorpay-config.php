<?php
/**
 * Single source of truth for Razorpay credentials - both
 * create-razorpay-order.php and verify-payment.php must use the SAME
 * key_secret, or signature verification can never succeed (the signature
 * is an HMAC of the order+payment id keyed with this secret).
 *
 * !! Set the real secret via the RAZORPAY_KEY_SECRET environment variable
 * on the server (or replace the fallback below) before going live -
 * payments cannot be created or verified without it.
 */
define('RAZORPAY_KEY_ID', getenv('RAZORPAY_KEY_ID') ?: 'rzp_live_TUUuGaHfai8zhj');
define('RAZORPAY_KEY_SECRET', getenv('RAZORPAY_KEY_SECRET') ?: 'REPLACE_WITH_YOUR_RAZORPAY_KEY_SECRET');

/**
 * Separate secret for razorpay-webhook.php, set in the Razorpay Dashboard
 * under Settings > Webhooks when you add the webhook URL. NOT the same
 * value as RAZORPAY_KEY_SECRET - webhooks are signed with their own secret.
 */
define('RAZORPAY_WEBHOOK_SECRET', getenv('RAZORPAY_WEBHOOK_SECRET') ?: 'REPLACE_WITH_YOUR_RAZORPAY_WEBHOOK_SECRET');
?>
