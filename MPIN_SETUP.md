# M-PIN Database Setup Guide

## Overview
M-PIN (Mobile Personal Identification Number) is a 4-digit PIN that users set during their first login and can reuse across devices without needing OTP each time.

## Database Setup

### SQL Query to Create M-PIN Table

```sql
CREATE TABLE IF NOT EXISTS user_mpin (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    mpin_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_phone (phone_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Steps to Setup:

1. **Run Migration Script** (Optional - Automatic)
   - Open browser and visit: `http://localhost/maha-maintainpro/api/create-mpin-table.php`
   - This will automatically create the table if it doesn't exist

2. **Manual Setup** (If migration fails)
   - Open your MySQL client (phpMyAdmin, MySQL Workbench, etc.)
   - Select database: `digitrix_maha_maintain_pro`
   - Paste and execute the SQL query above

## How It Works

### User Flow:
```
Login → OTP Verification → M-PIN Setup → Dashboard
                                ↓
                        Next Login:
                        M-PIN Login → Dashboard
```

### Database Schema:

| Column | Type | Description |
|--------|------|-------------|
| id | INT | Primary key, auto-increment |
| phone_number | VARCHAR(20) | User's phone number (UNIQUE) |
| mpin_hash | VARCHAR(255) | Bcrypt-hashed M-PIN (never store plain text) |
| created_at | TIMESTAMP | When M-PIN was first set |
| updated_at | TIMESTAMP | When M-PIN was last updated |

## API Endpoints

### 1. Save/Set M-PIN
**Endpoint:** `POST /api/save-mpin.php`

**Request:**
```json
{
    "phone_number": "+919876543210",
    "mpin": "1234"
}
```

**Response (Success):**
```json
{
    "success": true,
    "message": "M-PIN saved successfully"
}
```

**Response (Error):**
```json
{
    "success": false,
    "error": "Database connection failed"
}
```

### 2. Verify M-PIN
**Endpoint:** `POST /api/verify-mpin.php`

**Request:**
```json
{
    "phone_number": "+919876543210",
    "mpin": "1234"
}
```

**Response (Success):**
```json
{
    "success": true,
    "message": "M-PIN verified successfully"
}
```

**Response (Error):**
```json
{
    "success": false,
    "error": "Incorrect M-PIN"
}
```

### 3. Check If M-PIN Exists
**Endpoint:** `GET /api/check-mpin.php?phone_number=+919876543210`

**Response:**
```json
{
    "success": true,
    "exists": true,
    "phone_number": "+919876543210"
}
```

## Security Features

1. **Bcrypt Hashing** - M-PIN is hashed using PHP's `password_hash()` with BCRYPT algorithm
2. **Password Verify** - Comparison uses `password_verify()` to prevent timing attacks
3. **Unique Phone Number** - Each phone number can only have one M-PIN
4. **No Plain Text Storage** - M-PIN is never stored in plain text

## Configuration

In `lib/repositories/auth_repository.dart`:
```dart
static const String API_BASE_URL = 'http://localhost/maha-maintainpro/api';
```

Update `API_BASE_URL` to your server URL when deploying to production.

## Testing

### Test with cURL:

**Set M-PIN:**
```bash
curl -X POST http://localhost/maha-maintainpro/api/save-mpin.php \
  -H "Content-Type: application/json" \
  -d '{"phone_number":"+919876543210","mpin":"1234"}'
```

**Verify M-PIN:**
```bash
curl -X POST http://localhost/maha-maintainpro/api/verify-mpin.php \
  -H "Content-Type: application/json" \
  -d '{"phone_number":"+919876543210","mpin":"1234"}'
```

**Check if M-PIN exists:**
```bash
curl "http://localhost/maha-maintainpro/api/check-mpin.php?phone_number=%2B919876543210"
```

## Demo Mode

In demo mode (DEMO_MODE = true), the app simulates M-PIN operations without database calls. This is useful for testing without a real database setup.

## Useful SQL Queries

**View all M-PIN entries (without hashes):**
```sql
SELECT id, phone_number, created_at, updated_at FROM user_mpin;
```

**Check if M-PIN exists for a phone:**
```sql
SELECT EXISTS(SELECT 1 FROM user_mpin WHERE phone_number = '+919876543210') as exists;
```

**Reset/Delete M-PIN for a user:**
```sql
DELETE FROM user_mpin WHERE phone_number = '+919876543210';
```

**Update M-PIN (after it's been used):**
```sql
UPDATE user_mpin 
SET mpin_hash = PASSWORD('new_hash_here') 
WHERE phone_number = '+919876543210';
```

## Troubleshooting

### "phone_number not found" Error
- User must login with OTP first
- Phone number is stored in session when OTP is verified

### "Incorrect M-PIN" Error  
- User entered wrong M-PIN
- M-PIN is case-sensitive and must be exactly 4 digits
- Check for leading zeros

### "Database connection failed"
- Check database credentials in API files
- Verify database server is running
- Check network connectivity

## Files Modified/Created

- ✅ `api/create-mpin-table.php` - Auto-create M-PIN table
- ✅ `api/save-mpin.php` - Set user's M-PIN
- ✅ `api/verify-mpin.php` - Verify user's M-PIN
- ✅ `api/check-mpin.php` - Check if M-PIN exists
- ✅ `lib/repositories/auth_repository.dart` - Backend integration
- ✅ `lib/screens/mpin_login_screen.dart` - M-PIN login UI
- ✅ `lib/screens/mpin_setup_screen.dart` - M-PIN setup UI
- ✅ `lib/config/app_router.dart` - Route configuration
