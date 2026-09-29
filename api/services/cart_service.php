<?php
/**
 * CART SERVICE - Core cart operations
 * Abstraction layer for all cart-related database operations
 * Reusable across all cart endpoints
 */

class CartService {
    private $conn;
    private $user_id;
    private $cart_id;

    public function __construct($conn, $user_id) {
        $this->conn = $conn;
        $this->user_id = $user_id;
    }

    /**
     * Get or create cart for user
     */
    public function initCart($service_location_id = null) {
        try {
            // Check if active cart exists
            $stmt = $this->conn->prepare(
                "SELECT cart_id FROM carts
                 WHERE user_id = ? AND status = 'active'
                 AND created_at > DATE_SUB(NOW(), INTERVAL 24 HOUR)
                 LIMIT 1"
            );
            $stmt->bind_param("s", $this->user_id);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows > 0) {
                $row = $result->fetch_assoc();
                $this->cart_id = $row['cart_id'];
            } else {
                // Create new cart
                $this->cart_id = 'CART_' . $this->user_id . '_' . time();
                $stmt = $this->conn->prepare(
                    "INSERT INTO carts (cart_id, user_id, service_location_id, status, expires_at)
                     VALUES (?, ?, ?, 'active', DATE_ADD(NOW(), INTERVAL 24 HOUR))"
                );
                $stmt->bind_param("ssi", $this->cart_id, $this->user_id, $service_location_id);
                $stmt->execute();
            }
            return $this->cart_id;
        } catch (Exception $e) {
            throw new Exception("Error initializing cart: " . $e->getMessage());
        }
    }

    /**
     * Add item to cart
     */
    public function addItem($service_id, $package_id, $quantity, $selected_addons = [], $options = null, $provider_id = null) {
        try {
            if (!$this->cart_id) {
                throw new Exception("Cart not initialized");
            }

            // Validate service exists and is active
            $stmt = $this->conn->prepare("SELECT id, price FROM services WHERE id = ? AND is_active = 1 LIMIT 1");
            $stmt->bind_param("i", $service_id);
            $stmt->execute();
            $service = $stmt->get_result()->fetch_assoc();

            if (!$service) {
                throw new Exception("Service not found or inactive");
            }

            // Get package price if specified
            $unit_price = $service['price'];
            if ($package_id) {
                $stmt = $this->conn->prepare("SELECT price FROM service_packages WHERE id = ? AND service_id = ? LIMIT 1");
                $stmt->bind_param("ii", $package_id, $service_id);
                $stmt->execute();
                $package = $stmt->get_result()->fetch_assoc();
                if ($package) {
                    $unit_price = $package['price'];
                }
            }

            // Calculate item subtotal (price + addons)
            $addon_total = 0;
            $addon_details = [];

            if (!empty($selected_addons)) {
                $addon_ids_str = implode(',', array_map('intval', $selected_addons));
                $stmt = $this->conn->prepare(
                    "SELECT id, name, price FROM service_addons
                     WHERE id IN ($addon_ids_str) AND service_id = ? AND is_active = 1"
                );
                $stmt->bind_param("i", $service_id);
                $stmt->execute();
                $addons = $stmt->get_result();

                while ($addon = $addons->fetch_assoc()) {
                    $addon_total += $addon['price'];
                    $addon_details[] = $addon;
                }
            }

            $item_subtotal = ($unit_price + $addon_total) * $quantity;

            // Insert cart item
            $options_json = json_encode($options);
            $stmt = $this->conn->prepare(
                "INSERT INTO cart_items (cart_id, service_id, package_id, quantity, unit_price, duration_minutes, item_subtotal, options, provider_id)
                 VALUES (?, ?, ?, ?, ?, NULL, ?, ?, ?)"
            );
            $stmt->bind_param("siiiidsi", $this->cart_id, $service_id, $package_id, $quantity, $unit_price, $item_subtotal, $options_json, $provider_id);
            $stmt->execute();

            $cart_item_id = $this->conn->insert_id;

            // Insert addons
            foreach ($addon_details as $addon) {
                $stmt = $this->conn->prepare(
                    "INSERT INTO cart_item_addons (cart_item_id, addon_id, addon_name, addon_price)
                     VALUES (?, ?, ?, ?)"
                );
                $stmt->bind_param("iisi", $cart_item_id, $addon['id'], $addon['name'], $addon['price']);
                $stmt->execute();
            }

            // Update cart totals
            $this->recalculatePricing();

            return ['success' => true, 'cart_item_id' => $cart_item_id];
        } catch (Exception $e) {
            throw new Exception("Error adding item: " . $e->getMessage());
        }
    }

    /**
     * Update cart item quantity or details
     */
    public function updateItem($cart_item_id, $quantity = null, $selected_addons = null, $options = null, $provider_id = null) {
        try {
            // Update quantity
            if ($quantity !== null) {
                $stmt = $this->conn->prepare("UPDATE cart_items SET quantity = ? WHERE id = ? AND cart_id = ?");
                $stmt->bind_param("iis", $quantity, $cart_item_id, $this->cart_id);
                $stmt->execute();
            }

            // Update addons if provided
            if ($selected_addons !== null) {
                $stmt = $this->conn->prepare("DELETE FROM cart_item_addons WHERE cart_item_id = ?");
                $stmt->bind_param("i", $cart_item_id);
                $stmt->execute();

                $stmt = $this->conn->prepare(
                    "SELECT service_id FROM cart_items WHERE id = ? LIMIT 1"
                );
                $stmt->bind_param("i", $cart_item_id);
                $stmt->execute();
                $item = $stmt->get_result()->fetch_assoc();

                foreach ($selected_addons as $addon_id) {
                    $stmt = $this->conn->prepare(
                        "SELECT id, name, price FROM service_addons WHERE id = ? LIMIT 1"
                    );
                    $stmt->bind_param("i", $addon_id);
                    $stmt->execute();
                    $addon = $stmt->get_result()->fetch_assoc();

                    if ($addon) {
                        $stmt = $this->conn->prepare(
                            "INSERT INTO cart_item_addons (cart_item_id, addon_id, addon_name, addon_price)
                             VALUES (?, ?, ?, ?)"
                        );
                        $stmt->bind_param("iisi", $cart_item_id, $addon['id'], $addon['name'], $addon['price']);
                        $stmt->execute();
                    }
                }
            }

            // Update options
            if ($options !== null) {
                $options_json = json_encode($options);
                $stmt = $this->conn->prepare("UPDATE cart_items SET options = ? WHERE id = ? AND cart_id = ?");
                $stmt->bind_param("sis", $options_json, $cart_item_id, $this->cart_id);
                $stmt->execute();
            }

            // Update provider
            if ($provider_id !== null) {
                $stmt = $this->conn->prepare("UPDATE cart_items SET provider_id = ? WHERE id = ? AND cart_id = ?");
                $stmt->bind_param("iis", $provider_id, $cart_item_id, $this->cart_id);
                $stmt->execute();
            }

            $this->recalculatePricing();
            return ['success' => true];
        } catch (Exception $e) {
            throw new Exception("Error updating item: " . $e->getMessage());
        }
    }

    /**
     * Remove item from cart
     */
    public function removeItem($cart_item_id) {
        try {
            $stmt = $this->conn->prepare("DELETE FROM cart_item_addons WHERE cart_item_id = ?");
            $stmt->bind_param("i", $cart_item_id);
            $stmt->execute();

            $stmt = $this->conn->prepare("DELETE FROM cart_items WHERE id = ? AND cart_id = ?");
            $stmt->bind_param("is", $cart_item_id, $this->cart_id);
            $stmt->execute();

            $this->recalculatePricing();
            return ['success' => true];
        } catch (Exception $e) {
            throw new Exception("Error removing item: " . $e->getMessage());
        }
    }

    /**
     * Recalculate cart pricing
     */
    public function recalculatePricing() {
        try {
            $stmt = $this->conn->prepare(
                "SELECT SUM(ci.item_subtotal) as subtotal
                 FROM cart_items ci
                 WHERE ci.cart_id = ?"
            );
            $stmt->bind_param("s", $this->cart_id);
            $stmt->execute();
            $result = $stmt->get_result()->fetch_assoc();
            $subtotal = $result['subtotal'] ?? 0;

            // Get cart details
            $stmt = $this->conn->prepare("SELECT service_location_id, coupon_id FROM carts WHERE cart_id = ?");
            $stmt->bind_param("s", $this->cart_id);
            $stmt->execute();
            $cart = $stmt->get_result()->fetch_assoc();

            $service_fee = 0;
            $travel_fee = 0;
            $tax_rate = 18.00; // Default GST

            // Calculate travel fee based on location
            if ($cart['service_location_id']) {
                // TODO: Get travel fee from service_location_config
            }

            // Calculate tax
            $tax_amount = ($subtotal * $tax_rate) / 100;

            // Apply coupon if any
            $discount_amount = 0;
            if ($cart['coupon_id']) {
                $stmt = $this->conn->prepare(
                    "SELECT discount_type, discount_value, max_discount FROM coupons WHERE id = ?"
                );
                $stmt->bind_param("i", $cart['coupon_id']);
                $stmt->execute();
                $coupon = $stmt->get_result()->fetch_assoc();

                if ($coupon['discount_type'] === 'percentage') {
                    $discount_amount = ($subtotal * $coupon['discount_value']) / 100;
                    if ($coupon['max_discount']) {
                        $discount_amount = min($discount_amount, $coupon['max_discount']);
                    }
                } else {
                    $discount_amount = $coupon['discount_value'];
                }
            }

            $total_amount = $subtotal + $service_fee + $travel_fee + $tax_amount - $discount_amount;

            // Update cart totals
            $stmt = $this->conn->prepare(
                "UPDATE carts SET subtotal = ?, discount_amount = ?, service_fee = ?,
                 travel_fee = ?, tax_amount = ?, total_amount = ?, updated_at = NOW()
                 WHERE cart_id = ?"
            );
            $stmt->bind_param("dddddds", $subtotal, $discount_amount, $service_fee, $travel_fee, $tax_amount, $total_amount, $this->cart_id);
            $stmt->execute();

            return ['success' => true];
        } catch (Exception $e) {
            throw new Exception("Error recalculating pricing: " . $e->getMessage());
        }
    }

    /**
     * Get complete cart with all details
     */
    public function getCart() {
        try {
            $stmt = $this->conn->prepare(
                "SELECT * FROM carts WHERE cart_id = ?"
            );
            $stmt->bind_param("s", $this->cart_id);
            $stmt->execute();
            $cart = $stmt->get_result()->fetch_assoc();

            if (!$cart) {
                throw new Exception("Cart not found");
            }

            // Get cart items
            $stmt = $this->conn->prepare(
                "SELECT ci.*, s.name as service_name, sp.name as package_name
                 FROM cart_items ci
                 JOIN services s ON ci.service_id = s.id
                 LEFT JOIN service_packages sp ON ci.package_id = sp.id
                 WHERE ci.cart_id = ?"
            );
            $stmt->bind_param("s", $this->cart_id);
            $stmt->execute();
            $items_result = $stmt->get_result();
            $items = [];

            while ($item = $items_result->fetch_assoc()) {
                // Get addons for this item
                $addon_stmt = $this->conn->prepare(
                    "SELECT * FROM cart_item_addons WHERE cart_item_id = ?"
                );
                $addon_stmt->bind_param("i", $item['id']);
                $addon_stmt->execute();
                $item['addons'] = $addon_stmt->get_result()->fetch_all(MYSQLI_ASSOC);
                $items[] = $item;
            }

            $cart['items'] = $items;
            $cart['item_count'] = count($items);
            return $cart;
        } catch (Exception $e) {
            throw new Exception("Error fetching cart: " . $e->getMessage());
        }
    }

    /**
     * Clear cart
     */
    public function clearCart() {
        try {
            $stmt = $this->conn->prepare("DELETE FROM cart_item_addons WHERE cart_item_id IN (SELECT id FROM cart_items WHERE cart_id = ?)");
            $stmt->bind_param("s", $this->cart_id);
            $stmt->execute();

            $stmt = $this->conn->prepare("DELETE FROM cart_items WHERE cart_id = ?");
            $stmt->bind_param("s", $this->cart_id);
            $stmt->execute();

            $stmt = $this->conn->prepare("DELETE FROM cart_discounts WHERE cart_id = ?");
            $stmt->bind_param("s", $this->cart_id);
            $stmt->execute();

            $stmt = $this->conn->prepare("UPDATE carts SET status = 'abandoned', updated_at = NOW() WHERE cart_id = ?");
            $stmt->bind_param("s", $this->cart_id);
            $stmt->execute();

            return ['success' => true];
        } catch (Exception $e) {
            throw new Exception("Error clearing cart: " . $e->getMessage());
        }
    }

    public function getCartId() {
        return $this->cart_id;
    }

    public function setCartId($cart_id) {
        $this->cart_id = $cart_id;
    }
}
?>
