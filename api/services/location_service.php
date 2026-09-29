<?php
/**
 * LOCATION SERVICE - Service location and serviceability checks
 * Handles service location configuration and serviceability validation
 */

class LocationService {
    private $conn;

    public function __construct($conn) {
        $this->conn = $conn;
    }

    /**
     * Check if service is available at location
     */
    public function isServiceable($service_id, $location_id, $check_time = null) {
        try {
            if (!$check_time) {
                $check_time = date('H:i:s');
            }

            $stmt = $this->conn->prepare(
                "SELECT sc.*, a.address
                 FROM service_location_config sc
                 LEFT JOIN addresses a ON sc.service_id = a.id
                 WHERE sc.service_id = ? AND sc.service_id = ?
                 LIMIT 1"
            );
            $stmt->bind_param("ii", $service_id, $location_id);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                return [
                    'serviceable' => false,
                    'reason' => 'Service not available at this location'
                ];
            }

            $config = $result->fetch_assoc();

            if (!$config['is_serviceable']) {
                return [
                    'serviceable' => false,
                    'reason' => 'Service temporarily unavailable'
                ];
            }

            // Check time availability
            if (strcmp($check_time, $config['available_from']) < 0 ||
                strcmp($check_time, $config['available_until']) > 0) {
                return [
                    'serviceable' => false,
                    'reason' => 'Service not available at this time. Available: ' .
                               $config['available_from'] . ' - ' . $config['available_until']
                ];
            }

            return [
                'serviceable' => true,
                'travel_fee' => $config['travel_fee'],
                'tax_rate' => $config['tax_rate'],
                'available_from' => $config['available_from'],
                'available_until' => $config['available_until']
            ];
        } catch (Exception $e) {
            throw new Exception("Error checking serviceability: " . $e->getMessage());
        }
    }

    /**
     * Get service configuration for location
     */
    public function getLocationConfig($service_id, $location_id) {
        try {
            $stmt = $this->conn->prepare(
                "SELECT * FROM service_location_config
                 WHERE service_id = ? AND service_id = ?"
            );
            $stmt->bind_param("ii", $service_id, $location_id);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                throw new Exception("Location configuration not found");
            }

            return $result->fetch_assoc();
        } catch (Exception $e) {
            throw new Exception("Error getting location config: " . $e->getMessage());
        }
    }

    /**
     * Get all serviceable locations for a service
     */
    public function getServiceableLocations($service_id) {
        try {
            $stmt = $this->conn->prepare(
                "SELECT location_name, pincode, travel_fee, tax_rate,
                        available_from, available_until, is_serviceable
                 FROM service_location_config
                 WHERE service_id = ? AND is_serviceable = 1
                 ORDER BY location_name ASC"
            );
            $stmt->bind_param("i", $service_id);
            $stmt->execute();
            $result = $stmt->get_result();

            $locations = [];
            while ($loc = $result->fetch_assoc()) {
                $locations[] = $loc;
            }

            return $locations;
        } catch (Exception $e) {
            throw new Exception("Error getting serviceable locations: " . $e->getMessage());
        }
    }

    /**
     * Check serviceability by pincode
     */
    public function isServiceableByPincode($service_id, $pincode) {
        try {
            $stmt = $this->conn->prepare(
                "SELECT * FROM service_location_config
                 WHERE service_id = ? AND pincode = ? AND is_serviceable = 1
                 LIMIT 1"
            );
            $stmt->bind_param("is", $service_id, $pincode);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                return [
                    'serviceable' => false,
                    'reason' => 'Service not available in your area'
                ];
            }

            $config = $result->fetch_assoc();

            return [
                'serviceable' => true,
                'location' => $config['location_name'],
                'travel_fee' => $config['travel_fee'],
                'tax_rate' => $config['tax_rate'],
                'available_from' => $config['available_from'],
                'available_until' => $config['available_until']
            ];
        } catch (Exception $e) {
            throw new Exception("Error checking pincode serviceability: " . $e->getMessage());
        }
    }

    /**
     * Get travel fee for location
     */
    public function getTravelFee($service_id, $location_id) {
        try {
            $stmt = $this->conn->prepare(
                "SELECT travel_fee FROM service_location_config
                 WHERE service_id = ? AND service_id = ? LIMIT 1"
            );
            $stmt->bind_param("ii", $service_id, $location_id);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                return 0;
            }

            $config = $result->fetch_assoc();
            return $config['travel_fee'] ?? 0;
        } catch (Exception $e) {
            throw new Exception("Error getting travel fee: " . $e->getMessage());
        }
    }

    /**
     * Get tax rate for location
     */
    public function getTaxRate($service_id, $location_id) {
        try {
            $stmt = $this->conn->prepare(
                "SELECT tax_rate FROM service_location_config
                 WHERE service_id = ? AND service_id = ? LIMIT 1"
            );
            $stmt->bind_param("ii", $service_id, $location_id);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                return 18; // Default tax rate
            }

            $config = $result->fetch_assoc();
            return $config['tax_rate'] ?? 18;
        } catch (Exception $e) {
            throw new Exception("Error getting tax rate: " . $e->getMessage());
        }
    }
}
?>
