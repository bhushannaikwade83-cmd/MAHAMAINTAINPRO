<?php
/**
 * CANCELLATION SERVICE - Booking cancellation and refunds
 * Handles booking cancellations, refund calculations, and slot release
 */

class CancellationService {
    private $conn;

    public function __construct($conn) {
        $this->conn = $conn;
    }

    /**
     * Cancel booking with refund
     */
    public function cancelBooking($booking_id, $user_id, $reason = null) {
        try {
            $this->conn->begin_transaction();

            // Get booking details
            $stmt = $this->conn->prepare("SELECT * FROM bookings WHERE booking_id = ? FOR UPDATE");
            $stmt->bind_param("s", $booking_id);
            $stmt->execute();
            $booking = $stmt->fetch();

            if (!$booking) {
                throw new Exception("Booking not found");
            }

            // Verify ownership
            if ($booking['user_id'] !== $user_id) {
                throw new Exception("Unauthorized");
            }

            // Check if booking can be cancelled
            if (in_array($booking['status'], ['cancelled', 'completed'])) {
                throw new Exception("Booking cannot be cancelled");
            }

            // Calculate refund based on cancellation policy
            $refund_amount = $this->calculateRefund($booking);

            if ($refund_amount < 0) {
                throw new Exception("Invalid refund calculation");
            }

            // Update booking status
            $cancelled_at = date('Y-m-d H:i:s');
            $stmt = $this->conn->prepare(
                "UPDATE bookings
                 SET status = 'cancelled',
                     cancelled_at = ?,
                     cancellation_reason = ?,
                     refund_amount = ?
                 WHERE booking_id = ?"
            );
            $stmt->bind_param("ssds", $cancelled_at, $reason, $refund_amount, $booking_id);
            $stmt->execute();

            // Release time slot
            $stmt = $this->conn->prepare(
                "UPDATE service_time_slots
                 SET remaining_capacity = remaining_capacity + 1,
                     booked_count = booked_count - 1
                 WHERE id = ?"
            );
            $stmt->bind_param("i", $booking['time_slot_id']);
            $stmt->execute();

            // Create refund record
            $refund_id = 'REFUND_' . $user_id . '_' . time();
            $stmt = $this->conn->prepare(
                "INSERT INTO refunds (refund_id, booking_id, amount, status, reason, created_at)
                 VALUES (?, ?, ?, 'initiated', ?, NOW())"
            );
            $stmt->bind_param("ssds", $refund_id, $booking_id, $refund_amount, $reason);
            $stmt->execute();

            $this->conn->commit();

            return [
                'success' => true,
                'booking_id' => $booking_id,
                'status' => 'cancelled',
                'refund_id' => $refund_id,
                'refund_amount' => $refund_amount,
                'message' => 'Booking cancelled. Refund of ₹' . number_format($refund_amount, 2) . ' will be processed.'
            ];
        } catch (Exception $e) {
            $this->conn->rollback();
            throw $e;
        }
    }

    /**
     * Calculate refund amount based on cancellation policy
     */
    private function calculateRefund($booking) {
        $booking_amount = $booking['amount'];
        $booked_time = strtotime($booking['scheduled_date'] . ' ' . $booking['time_slot_id']);
        $current_time = time();
        $hours_until_service = ($booked_time - $current_time) / 3600;

        // Cancellation policy
        if ($hours_until_service >= 24) {
            // More than 24 hours: 100% refund
            return $booking_amount;
        } elseif ($hours_until_service >= 6) {
            // 6-24 hours: 80% refund
            return $booking_amount * 0.80;
        } elseif ($hours_until_service >= 2) {
            // 2-6 hours: 50% refund
            return $booking_amount * 0.50;
        } else {
            // Less than 2 hours: No refund
            return 0;
        }
    }

    /**
     * Get cancellation policy
     */
    public function getCancellationPolicy($booking_id) {
        try {
            $stmt = $this->conn->prepare(
                "SELECT scheduled_date, time_slot_id, amount FROM bookings WHERE booking_id = ?"
            );
            $stmt->bind_param("s", $booking_id);
            $stmt->execute();
            $booking = $stmt->fetch();

            if (!$booking) {
                throw new Exception("Booking not found");
            }

            $booked_time = strtotime($booking['scheduled_date']);
            $current_time = time();
            $hours_until_service = ($booked_time - $current_time) / 3600;

            $policies = [
                ['hours' => 24, 'refund_percent' => 100, 'condition' => 'More than 24 hours'],
                ['hours' => 6, 'refund_percent' => 80, 'condition' => '6-24 hours'],
                ['hours' => 2, 'refund_percent' => 50, 'condition' => '2-6 hours'],
                ['hours' => 0, 'refund_percent' => 0, 'condition' => 'Less than 2 hours']
            ];

            $applicable_policy = null;
            foreach ($policies as $policy) {
                if ($hours_until_service >= $policy['hours']) {
                    $applicable_policy = $policy;
                    break;
                }
            }

            if (!$applicable_policy) {
                $applicable_policy = $policies[3]; // No refund
            }

            $refund_amount = $booking['amount'] * ($applicable_policy['refund_percent'] / 100);

            return [
                'success' => true,
                'booking_id' => $booking_id,
                'hours_until_service' => round($hours_until_service, 1),
                'original_amount' => $booking['amount'],
                'applicable_policy' => $applicable_policy['condition'],
                'refund_percent' => $applicable_policy['refund_percent'],
                'estimated_refund' => $refund_amount,
                'all_policies' => $policies
            ];
        } catch (Exception $e) {
            throw new Exception("Error getting cancellation policy: " . $e->getMessage());
        }
    }

    /**
     * Get refund status
     */
    public function getRefundStatus($refund_id) {
        try {
            $stmt = $this->conn->prepare("SELECT * FROM refunds WHERE refund_id = ?");
            $stmt->bind_param("s", $refund_id);
            $stmt->execute();
            $refund = $stmt->fetch();

            if (!$refund) {
                throw new Exception("Refund not found");
            }

            return $refund;
        } catch (Exception $e) {
            throw new Exception("Error getting refund status: " . $e->getMessage());
        }
    }
}
?>
