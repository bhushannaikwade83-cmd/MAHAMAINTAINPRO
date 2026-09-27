-- M-PIN table for storing user M-PINs
-- Run this query to create the table

CREATE TABLE IF NOT EXISTS user_mpin (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    mpin_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_phone (phone_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Example queries:

-- To check if M-PIN exists for a phone number:
SELECT EXISTS(SELECT 1 FROM user_mpin WHERE phone_number = '+919876543210') as mpin_exists;

-- To view all M-PIN entries (without hash):
SELECT id, phone_number, created_at, updated_at FROM user_mpin;

-- To delete M-PIN for a phone number:
DELETE FROM user_mpin WHERE phone_number = '+919876543210';
