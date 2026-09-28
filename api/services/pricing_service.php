<?php
/**
 * PRICING SERVICE - Handles all pricing calculations
 * Server-side pricing engine (NEVER trust client prices)
 * Reusable across cart, checkout, and admin
 */

class PricingService {
    private $conn;

    public function __construct($conn) {
        $this->conn = $conn;
    }

    /**
     * Calculate complete pricing for a cart
     * Returns all pricing components for transparency
     */
    public function calculateCartPricing($cart_id, $service_location_id = null, $coupon_id = null) {
        try {
            $pricing = [
                'items_subtotal' => 0,
                'items' => [],
                'addons_total' => 0,
                'service_fee' => 0,
                'travel_fee' => 0,
                'tax_rate' => 18.00,
                'tax_amount' => 0,
                'coupon' => null,
                'discount_amount' => 0,
                'total' => 0,
                'currency' => 'INR'
            ];

            // Get all cart items with prices
            $stmt = $this->conn->prepare(
                "SELECT ci.*, s.id as service_id, s.min_booking_value, s.platform_fee, sp.name as package_name
                 FROM cart_items ci
                 JOIN services s ON ci.service_id = s.id
                 LEFT JOIN service_packages sp ON ci.package_id = sp.id
                 WHERE ci.cart_id = ?"
            );
            $stmt->bind_param("s", $cart_id);
            $stmt->execute();
            $items_result = $stmt->get_result();

            $total_item_price = 0;

            while ($item = $items_result->fetch_assoc()) {
                // Base price
                $item_price = $item['unit_price'];

                // Get addon prices for this item
                $addon_stmt = $this->conn->prepare(
                    "SELECT SUM(addon_price) as addon_total FROM cart_item_addons WHERE cart_item_id = ?"
                );
                $addon_stmt->bind_param("i", $item['id']);
                $addon_stmt->execute();
                $addon_data = $addon_stmt->get_result()->fetch_assoc();
                $addon_price = $addon_data['addon_total'] ?? 0;

                // Line item total
                $item_total = ($item_price + $addon_price) * $item['quantity'];
                $total_item_price += $item_total;

                $pricing['items'][] = [
                    'cart_item_id' => $item['id'],
                    'service_id' => $item['service_id'],
                    'service_name' => $item['service_name'] ?? 'Unknown Service',
                    'package_name' => $item['package_name'],
                    'quantity' => $item['quantity'],
                    'unit_price' => $item['unit_price'],
                    'addon_price' => $addon_price,
                    'line_total' => $item_total
                ];

                $pricing['addons_total'] += $addon_price * $item['quantity'];
            }

            $pricing['items_subtotal'] = $total_item_price;

            // Get service fee (if any service in cart has one)
            $stmt = $this->conn->prepare(
                "SELECT DISTINCT s.platform_fee FROM cart_items ci
                 JOIN services s ON ci.service_id = s.id
                 WHERE ci.cart_id = ? AND s.platform_fee > 0 LIMIT 1"
            );
            $stmt->bind_param("s", $cart_id);
            $stmt->execute();
            $fee_result = $stmt->get_result();
            if ($fee_result->num_rows > 0) {
                $fee_data = $fee_result->fetch_assoc();
                $pricing['service_fee'] = (float) $fee_data['platform_fee'];
            }

            // Get travel fee from service location
            if ($service_location_id) {
                $travel_fee = $this->getTravelFee($service_location_id);
                $pricing['travel_fee'] = (float) $travel_fee;

                // Get tax rate for location
                $tax_rate = $this->getTaxRate($service_location_id);
                $pricing['tax_rate'] = (float) $tax_rate;
            }

            // Calculate tax on subtotal (before discount)
            $tax_base = $pricing['items_subtotal'] + $pricing['service_fee'] + $pricing['travel_fee'];
            $pricing['tax_amount'] = round($tax_base * ($pricing['tax_rate'] / 100), 2);

            // Apply coupon if provided
            if ($coupon_id) {
                $coupon_result = $this->validateAndApplyCoupon($coupon_id, $pricing['items_subtotal']);
                if ($coupon_result['valid']) {
                    $pricing['coupon'] = [
                        'id' => $coupon_id,
                        'code' => $coupon_result['code'],
                        'discount_type' => $coupon_result['discount_type'],
                        'discount_value' => $coupon_result['discount_value'],
                        'discount_amount' => $coupon_result['discount_amount']
                    ];
                    $pricing['discount_amount'] = (float) $coupon_result['discount_amount'];
                }
            }

            // Calculate total
            $pricing['total'] = round(
                $pricing['items_subtotal'] +
                $pricing['service_fee'] +
                $pricing['travel_fee'] +
                $pricing['tax_amount'] -
                $pricing['discount_amount'],
                2
            );

            // Store pricing snapshot
            $this->savePricingSnapshot($cart_id, $pricing);

            return $pricing;
        } catch (Exception $e) {
            throw new Exception("Error calculating pricing: " . $e->getMessage());
        }
    }

    /**
     * Get travel fee for a location
     */
    private function getTravelFee($location_id) {
        try {
            // TODO: Implement logic to get travel fee based on service and location
            // For now, default to 0
            return 0;
        } catch (Exception $e) {
            return 0;
        }
    }

    /**
     * Get tax rate for a location
     */
    private function getTaxRate($location_id) {
        try {
            // Default GST rate for India
            return 18.00;
        } catch (Exception $e) {
            return 18.00;
        }
    }

    /**
     * Validate and apply coupon
     */
    public function validateAndApplyCoupon($coupon_id, $cart_value) {
        try {
            $stmt = $this->conn->prepare(
                "SELECT * FROM coupons WHERE id = ? AND is_active = 1"
            );
            $stmt->bind_param("i", $coupon_id);
            $stmt->execute();
            $coupon = $stmt->get_result()->fetch_assoc();

            if (!$coupon) {
                return ['valid' => false, 'message' => 'Coupon not found or inactive'];
            }

            // Check expiry
            if (strtotime($coupon['valid_until']) < time()) {
                return ['valid' => false, 'message' => 'Coupon has expired'];
            }

            // Check minimum value
            if ($cart_value < $coupon['min_amount']) {
                return ['valid' => false, 'message' => 'Cart value below minimum for this coupon'];
            }

            // Check usage limit
            if ($coupon['usage_limit'] && $coupon['usage_count'] >= $coupon['usage_limit']) {
                return ['valid' => false, 'message' => 'Coupon usage limit exceeded'];
            }

            // Calculate discount
            $discount_amount = 0;
            if ($coupon['discount_type'] === 'percentage') {
                $discount_amount = ($cart_value * $coupon['discount_value']) / 100;
                if ($coupon['max_discount']) {
                    $discount_amount = min($discount_amount, $coupon['max_discount']);
                }
            } else {
                $discount_amount = $coupon['discount_value'];
            }

            return [
                'valid' => true,
                'code' => $coupon['code'],
                'discount_type' => $coupon['discount_type'],
                'discount_value' => $coupon['discount_value'],
                'discount_amount' => round($discount_amount, 2)
            ];
        } catch (Exception $e) {
            return ['valid' => false, 'message' => 'Error validating coupon'];
        }
    }

    /**
     * Save pricing snapshot (for audit trail)
     */
    private function savePricingSnapshot($cart_id, $pricing) {
        try {
            $pricing_json = json_encode($pricing);
            $stmt = $this->conn->prepare(
                "INSERT INTO cart_pricing (cart_id, subtotal, addons_total, service_fee, travel_fee, tax_rate, tax_amount, discount_amount, total_amount)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                 ON DUPLICATE KEY UPDATE
                 subtotal = VALUES(subtotal),
                 addons_total = VALUES(addons_total),
                 service_fee = VALUES(service_fee),
                 travel_fee = VALUES(travel_fee),
                 tax_amount = VALUES(tax_amount),
                 discount_amount = VALUES(discount_amount),
                 total_amount = VALUES(total_amount)"
            );

            $stmt->bind_param(
                "sddddddd",
                $cart_id,
                $pricing['items_subtotal'],
                $pricing['addons_total'],
                $pricing['service_fee'],
                $pricing['travel_fee'],
                $pricing['tax_rate'],
                $pricing['tax_amount'],
                $pricing['discount_amount'],
                $pricing['total']
            );
            $stmt->execute();
        } catch (Exception $e) {
            // Logging only, don't fail
            error_log("Error saving pricing snapshot: " . $e->getMessage());
        }
    }

    /**
     * Detect price changes between two pricing snapshots
     */
    public function detectPriceChanges($old_pricing, $new_pricing) {
        $changes = [];

        if ($old_pricing['items_subtotal'] != $new_pricing['items_subtotal']) {
            $changes['subtotal'] = [
                'old' => $old_pricing['items_subtotal'],
                'new' => $new_pricing['items_subtotal'],
                'message' => "Subtotal changed from ₹{$old_pricing['items_subtotal']} to ₹{$new_pricing['items_subtotal']}"
            ];
        }

        if ($old_pricing['total'] != $new_pricing['total']) {
            $changes['total'] = [
                'old' => $old_pricing['total'],
                'new' => $new_pricing['total'],
                'message' => "Total changed from ₹{$old_pricing['total']} to ₹{$new_pricing['total']}"
            ];
        }

        return $changes;
    }

    /**
     * Format pricing for display
     */
    public function formatPricingForDisplay($pricing) {
        return [
            'subtotal' => '₹' . number_format($pricing['items_subtotal'], 2),
            'addons' => '₹' . number_format($pricing['addons_total'], 2),
            'service_fee' => '₹' . number_format($pricing['service_fee'], 2),
            'travel_fee' => '₹' . number_format($pricing['travel_fee'], 2),
            'tax' => '₹' . number_format($pricing['tax_amount'], 2) . ' (' . $pricing['tax_rate'] . '%)',
            'discount' => '₹' . number_format($pricing['discount_amount'], 2),
            'total' => '₹' . number_format($pricing['total'], 2)
        ];
    }
}
?>
