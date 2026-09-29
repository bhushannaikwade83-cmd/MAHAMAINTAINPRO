<?php
/**
 * CHECKOUT SERVICE - Checkout flow and booking creation
 * Handles checkout sessions, payment orders, and booking creation
 */

class CheckoutService {
    private $conn;
    private $user_id;

    public function __construct($conn, $user_id) {
        $this->conn = $conn;
        $this->user_id = $user_id;
    }

    /**
     * Initialize checkout session - lock prices and reserve slot
     */
    public function initCheckout($cart_id, $service_location_id, $scheduled_date, $time_slot_id, $pricing_details) {
        try {
            $this->conn->begin_transaction();

            // Generate checkout session ID
            $checkout_id = 'CHECKOUT_' . $this->user_id . '_' . time();

            // Get slot details and verify availability
            $stmt = $this->conn->prepare(
                "SELECT id, remaining_capacity FROM service_time_slots
                 WHERE id = ? AND slot_date = ? FOR UPDATE"
            );
            $stmt->bind_param("is", $time_slot_id, $scheduled_date);
            $stmt->execute();
            $slot_result = $stmt->get_result();

            if ($slot_result->num_rows === 0) {
                throw new Exception("Time slot not found");
            }

            $slot = $slot_result->fetch_assoc();
            if ($slot['remaining_capacity'] <= 0) {
                throw new Exception("Slot fully booked");
            }

            // Create checkout session with locked pricing
            $checkout_data = json_encode($pricing_details);
            $stmt = $this->conn->prepare(
                "INSERT INTO checkout_sessions
                (checkout_id, cart_id, user_id, service_location_id, scheduled_date, time_slot_id, pricing_snapshot, status, expires_at, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, 'initiated', DATE_ADD(NOW(), INTERVAL 15 MINUTE), NOW())"
            );
            $stmt->bind_param("sssisss", $checkout_id, $cart_id, $this->user_id, $service_location_id, $scheduled_date, $time_slot_id, $checkout_data);
            $stmt->execute();

            // Reserve slot (decrement capacity)
            $stmt = $this->conn->prepare(
                "UPDATE service_time_slots
                 SET remaining_capacity = remaining_capacity - 1,
                     booked_count = booked_count + 1
                 WHERE id = ?"
            );
            $stmt->bind_param("i", $time_slot_id);
            $stmt->execute();

            // Update cart status
            $stmt = $this->conn->prepare("UPDATE carts SET status = 'checkout_initiated' WHERE cart_id = ?");
            $stmt->bind_param("s", $cart_id);
            $stmt->execute();

            $this->conn->commit();

            return [
                'success' => true,
                'checkout_id' => $checkout_id,
                'cart_id' => $cart_id,
                'pricing' => $pricing_details,
                'expires_in_minutes' => 15
            ];
        } catch (Exception $e) {
            $this->conn->rollback();
            throw $e;
        }
    }

    /**
     * Create Razorpay payment order
     */
    public function createPaymentIntent($checkout_id, $amount, $razorpay_key, $razorpay_secret) {
        try {
            // Verify checkout exists
            $stmt = $this->conn->prepare("SELECT * FROM checkout_sessions WHERE checkout_id = ? AND status = 'initiated'");
            $stmt->bind_param("s", $checkout_id);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                throw new Exception("Invalid checkout session");
            }

            $checkout = $result->fetch_assoc();

            // Create Razorpay order
            $razorpay_url = "https://api.razorpay.com/v1/orders";
            $order_data = [
                'amount' => intval($amount * 100), // Amount in paise
                'currency' => 'INR',
                'receipt' => 'receipt_' . $checkout_id,
                'notes' => [
                    'checkout_id' => $checkout_id,
                    'user_id' => $this->user_id,
                    'cart_id' => $checkout['cart_id']
                ]
            ];

            $ch = curl_init();
            curl_setopt_array($ch, [
                CURLOPT_URL => $razorpay_url,
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_AUTH => [$razorpay_key, $razorpay_secret],
                CURLOPT_POSTFIELDS => http_build_query($order_data),
                CURLOPT_POST => true,
                CURLOPT_TIMEOUT => 10
            ]);

            $response = curl_exec($ch);
            $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            if ($http_code !== 201) {
                throw new Exception("Failed to create Razorpay order: " . $response);
            }

            $order = json_decode($response, true);

            // Store payment order in database
            $stmt = $this->conn->prepare(
                "UPDATE checkout_sessions
                 SET razorpay_order_id = ?, status = 'payment_initiated', payment_amount = ?
                 WHERE checkout_id = ?"
            );
            $stmt->bind_param("sds", $order['id'], $amount, $checkout_id);
            $stmt->execute();

            return [
                'success' => true,
                'checkout_id' => $checkout_id,
                'razorpay_order_id' => $order['id'],
                'amount' => $amount,
                'currency' => 'INR',
                'key' => $razorpay_key
            ];
        } catch (Exception $e) {
            throw $e;
        }
    }

    /**
     * Verify payment and create booking
     */
    public function verifyAndCreateBooking($checkout_id, $razorpay_payment_id, $razorpay_signature, $razorpay_key, $razorpay_secret) {
        try {
            $this->conn->begin_transaction();

            // Verify checkout exists
            $stmt = $this->conn->prepare(
                "SELECT * FROM checkout_sessions WHERE checkout_id = ? AND status = 'payment_initiated' FOR UPDATE"
            );
            $stmt->bind_param("s", $checkout_id);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                throw new Exception("Invalid checkout session");
            }

            $checkout = $result->fetch_assoc();

            // Verify Razorpay signature
            $this->verifyRazorpaySignature(
                $checkout['razorpay_order_id'],
                $razorpay_payment_id,
                $razorpay_signature,
                $razorpay_secret
            );

            // Get cart details
            $stmt = $this->conn->prepare("SELECT * FROM carts WHERE cart_id = ?");
            $stmt->bind_param("s", $checkout['cart_id']);
            $stmt->execute();
            $cart_result = $stmt->get_result();
            $cart = $cart_result->fetch_assoc();

            // Get cart items
            $stmt = $this->conn->prepare(
                "SELECT ci.*, s.vendor_id FROM cart_items ci
                 JOIN services s ON ci.service_id = s.id
                 WHERE ci.cart_id = ?"
            );
            $stmt->bind_param("s", $checkout['cart_id']);
            $stmt->execute();
            $items_result = $stmt->get_result();

            if ($items_result->num_rows === 0) {
                throw new Exception("Cart is empty");
            }

            $cart_item = $items_result->fetch_assoc();
            $vendor_id = $cart_item['vendor_id'];

            // Create booking
            $booking_id = 'BOOKING_' . $this->user_id . '_' . time();
            $pricing_snapshot = $checkout['pricing_snapshot'];

            $stmt = $this->conn->prepare(
                "INSERT INTO bookings
                (booking_id, user_id, vendor_id, service_id, customer_phone, scheduled_date, time_slot_id,
                 status, payment_id, payment_method, amount, notes, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, 'confirmed', ?, 'razorpay', ?, ?, NOW(), NOW())"
            );
            $stmt->bind_param(
                "siiisisisss",
                $booking_id, $this->user_id, $vendor_id, $cart_item['service_id'],
                $this->user_id, $checkout['scheduled_date'], $checkout['time_slot_id'],
                $razorpay_payment_id, $checkout['payment_amount'], $pricing_snapshot
            );
            $stmt->execute();

            // Create order
            $order_id = 'ORDER_' . $this->user_id . '_' . time();
            $stmt = $this->conn->prepare(
                "INSERT INTO orders
                (order_id, user_id, cart_id, checkout_session_id, service_id, vendor_id,
                 amount, tax_amount, order_status, payment_status, payment_method, price_snapshot, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'confirmed', 'paid', 'razorpay', ?, NOW())"
            );

            $tax_amount = $checkout['payment_amount'] * 0.18; // 18% tax
            $stmt->bind_param(
                "ssssiidss",
                $order_id, $this->user_id, $checkout['cart_id'], $checkout_id,
                $cart_item['service_id'], $vendor_id, $checkout['payment_amount'],
                $tax_amount, $pricing_snapshot
            );
            $stmt->execute();

            // Create order items
            $stmt = $this->conn->prepare(
                "INSERT INTO order_items
                (order_id, service_id, package_id, quantity, unit_price, total_price, addon_ids, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, NOW())"
            );

            $addon_ids_json = json_encode($cart_item['addon_ids'] ? json_decode($cart_item['addon_ids'], true) : []);
            $stmt->bind_param(
                "siiidds",
                $order_id, $cart_item['service_id'], $cart_item['package_id'],
                $cart_item['quantity'], $cart_item['unit_price'], $cart_item['item_subtotal'],
                $addon_ids_json
            );
            $stmt->execute();

            // Update checkout status
            $stmt = $this->conn->prepare(
                "UPDATE checkout_sessions
                 SET status = 'payment_verified', booking_id = ?, order_id = ?, razorpay_payment_id = ?
                 WHERE checkout_id = ?"
            );
            $stmt->bind_param("ssss", $booking_id, $order_id, $razorpay_payment_id, $checkout_id);
            $stmt->execute();

            // Clear cart
            $stmt = $this->conn->prepare("UPDATE carts SET status = 'checked_out' WHERE cart_id = ?");
            $stmt->bind_param("s", $checkout['cart_id']);
            $stmt->execute();

            $this->conn->commit();

            return [
                'success' => true,
                'booking_id' => $booking_id,
                'order_id' => $order_id,
                'payment_id' => $razorpay_payment_id,
                'status' => 'confirmed'
            ];
        } catch (Exception $e) {
            $this->conn->rollback();
            throw $e;
        }
    }

    /**
     * Verify Razorpay signature
     */
    private function verifyRazorpaySignature($order_id, $payment_id, $signature, $secret) {
        $payload = $order_id . '|' . $payment_id;
        $expected_signature = hash_hmac('sha256', $payload, $secret);

        if ($expected_signature !== $signature) {
            throw new Exception("Invalid payment signature");
        }
    }

    /**
     * Get checkout status
     */
    public function getCheckoutStatus($checkout_id) {
        try {
            $stmt = $this->conn->prepare("SELECT * FROM checkout_sessions WHERE checkout_id = ?");
            $stmt->bind_param("s", $checkout_id);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                throw new Exception("Checkout session not found");
            }

            return $result->fetch_assoc();
        } catch (Exception $e) {
            throw $e;
        }
    }

    /**
     * Cancel checkout and release slot
     */
    public function cancelCheckout($checkout_id) {
        try {
            $this->conn->begin_transaction();

            // Get checkout details
            $stmt = $this->conn->prepare("SELECT * FROM checkout_sessions WHERE checkout_id = ? FOR UPDATE");
            $stmt->bind_param("s", $checkout_id);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                throw new Exception("Checkout session not found");
            }

            $checkout = $result->fetch_assoc();

            // Only allow cancellation if payment not yet verified
            if ($checkout['status'] === 'payment_verified') {
                throw new Exception("Cannot cancel verified payment");
            }

            // Release reserved slot
            $stmt = $this->conn->prepare(
                "UPDATE service_time_slots
                 SET remaining_capacity = remaining_capacity + 1,
                     booked_count = booked_count - 1
                 WHERE id = ?"
            );
            $stmt->bind_param("i", $checkout['time_slot_id']);
            $stmt->execute();

            // Update checkout status
            $stmt = $this->conn->prepare("UPDATE checkout_sessions SET status = 'cancelled' WHERE checkout_id = ?");
            $stmt->bind_param("s", $checkout_id);
            $stmt->execute();

            $this->conn->commit();

            return ['success' => true, 'message' => 'Checkout cancelled'];
        } catch (Exception $e) {
            $this->conn->rollback();
            throw $e;
        }
    }
}
?>
