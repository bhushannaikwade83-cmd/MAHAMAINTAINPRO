-- Remove unnecessary fields from addresses table
-- Keep only: area (will store full address)
ALTER TABLE addresses DROP COLUMN IF EXISTS city;
ALTER TABLE addresses DROP COLUMN IF EXISTS taluka;
ALTER TABLE addresses DROP COLUMN IF EXISTS district;
ALTER TABLE addresses DROP COLUMN IF EXISTS state;

-- Verify remaining columns
DESCRIBE addresses;
