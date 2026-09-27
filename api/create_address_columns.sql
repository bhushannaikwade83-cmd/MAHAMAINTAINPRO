-- Create addresses table for multiple addresses per user
CREATE TABLE IF NOT EXISTS addresses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL,
    address_type VARCHAR(50) NOT NULL DEFAULT 'Home',
    building VARCHAR(255),
    building_name VARCHAR(255),
    street VARCHAR(255),
    pincode VARCHAR(10),
    area VARCHAR(255),
    city VARCHAR(255),
    taluka VARCHAR(255),
    district VARCHAR(255),
    state VARCHAR(255),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    label VARCHAR(100),
    delivery_instructions TEXT,
    full_address TEXT,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (phone_number) REFERENCES individuals(phone_number) ON DELETE CASCADE
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_phone_number ON addresses(phone_number);
CREATE INDEX IF NOT EXISTS idx_address_type ON addresses(address_type);
