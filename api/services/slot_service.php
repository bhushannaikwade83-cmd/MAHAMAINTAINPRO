<?php
/**
 * SLOT SERVICE - Slot availability and management
 * Handles real-time slot availability, reservations, and cancellations
 */

class SlotService {
    private $conn;

    public function __construct($conn) {
        $this->conn = $conn;
    }

    /**
     * Get available slots for a service on a specific date
     */
    public function getAvailableSlots($service_id, $slot_date) {
        try {
            // Validate date format
            if (!strtotime($slot_date)) {
                throw new Exception("Invalid date format");
            }

            // Ensure date is not in past
            if (strtotime($slot_date) < strtotime(date('Y-m-d'))) {
                throw new Exception("Cannot book for past dates");
            }

            $stmt = $this->conn->prepare(
                "SELECT id, slot_date, start_time, end_time,
                        remaining_capacity, booked_count,
                        (remaining_capacity > 0) as is_available
                 FROM service_time_slots
                 WHERE service_id = ? AND slot_date = ? AND is_active = 1
                 ORDER BY start_time ASC"
            );
            $stmt->bind_param("is", $service_id, $slot_date);
            $stmt->execute();
            $result = $stmt->get_result();

            $slots = [];
            while ($slot = $result->fetch_assoc()) {
                $slots[] = [
                    'id' => $slot['id'],
                    'date' => $slot['slot_date'],
                    'time' => $slot['start_time'] . ' - ' . $slot['end_time'],
                    'start_time' => $slot['start_time'],
                    'end_time' => $slot['end_time'],
                    'available' => (int)$slot['is_available'],
                    'booked' => $slot['booked_count'],
                    'capacity' => $slot['remaining_capacity']
                ];
            }

            return $slots;
        } catch (Exception $e) {
            throw new Exception("Error getting slots: " . $e->getMessage());
        }
    }

    /**
     * Check if slot is available for booking
     */
    public function isSlotAvailable($time_slot_id, $slot_date) {
        try {
            $stmt = $this->conn->prepare(
                "SELECT remaining_capacity, is_available FROM service_time_slots
                 WHERE id = ? AND slot_date = ?"
            );
            $stmt->bind_param("is", $time_slot_id, $slot_date);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                return ['available' => false, 'reason' => 'Slot not found'];
            }

            $slot = $result->fetch_assoc();

            if (!$slot['is_available']) {
                return ['available' => false, 'reason' => 'Slot not available'];
            }

            if ($slot['remaining_capacity'] <= 0) {
                return ['available' => false, 'reason' => 'Slot fully booked'];
            }

            return ['available' => true];
        } catch (Exception $e) {
            throw new Exception("Error checking slot: " . $e->getMessage());
        }
    }

    /**
     * Get available dates for next 30 days
     */
    public function getAvailableDates($service_id, $days_ahead = 30) {
        try {
            $available_dates = [];

            for ($i = 0; $i < $days_ahead; $i++) {
                $date = date('Y-m-d', strtotime("+$i days"));

                $stmt = $this->conn->prepare(
                    "SELECT COUNT(*) as total,
                            SUM(remaining_capacity) as available
                     FROM service_time_slots
                     WHERE service_id = ? AND slot_date = ? AND is_active = 1"
                );
                $stmt->bind_param("is", $service_id, $date);
                $stmt->execute();
                $result = $stmt->fetch();

                if ($result['total'] > 0 && $result['available'] > 0) {
                    $available_dates[] = [
                        'date' => $date,
                        'available_slots' => (int)$result['available']
                    ];
                }
            }

            return $available_dates;
        } catch (Exception $e) {
            throw new Exception("Error getting available dates: " . $e->getMessage());
        }
    }

    /**
     * Release slot reservation (when checkout is cancelled)
     */
    public function releaseSlotReservation($time_slot_id) {
        try {
            $stmt = $this->conn->prepare(
                "UPDATE service_time_slots
                 SET remaining_capacity = remaining_capacity + 1,
                     booked_count = booked_count - 1
                 WHERE id = ? AND booked_count > 0"
            );
            $stmt->bind_param("i", $time_slot_id);
            $stmt->execute();

            if ($stmt->affected_rows === 0) {
                throw new Exception("Slot not found or cannot release");
            }

            return ['success' => true, 'message' => 'Slot released'];
        } catch (Exception $e) {
            throw new Exception("Error releasing slot: " . $e->getMessage());
        }
    }

    /**
     * Get slot details
     */
    public function getSlotDetails($time_slot_id) {
        try {
            $stmt = $this->conn->prepare(
                "SELECT * FROM service_time_slots WHERE id = ?"
            );
            $stmt->bind_param("i", $time_slot_id);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                throw new Exception("Slot not found");
            }

            return $result->fetch_assoc();
        } catch (Exception $e) {
            throw new Exception("Error getting slot details: " . $e->getMessage());
        }
    }

    /**
     * Get slots for vendor/service with filters
     */
    public function getServiceSlots($service_id, $start_date, $end_date) {
        try {
            $stmt = $this->conn->prepare(
                "SELECT id, slot_date, start_time, end_time,
                        remaining_capacity, booked_count, is_active
                 FROM service_time_slots
                 WHERE service_id = ? AND slot_date BETWEEN ? AND ?
                 ORDER BY slot_date ASC, start_time ASC"
            );
            $stmt->bind_param("iss", $service_id, $start_date, $end_date);
            $stmt->execute();
            $result = $stmt->get_result();

            $slots = [];
            while ($slot = $result->fetch_assoc()) {
                $slots[] = $slot;
            }

            return $slots;
        } catch (Exception $e) {
            throw new Exception("Error getting service slots: " . $e->getMessage());
        }
    }
}
?>
