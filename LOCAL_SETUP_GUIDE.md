# Complete Local Setup & Execution Guide

## 🖥️ Prerequisites

**Required Software:**
- PHP 7.4+ with extensions: curl, json, pdo_mysql
- MySQL 5.7+ or MariaDB
- Flutter SDK (latest stable)
- Dart SDK (included with Flutter)
- Git
- VS Code or Android Studio

---

## 📦 Part 1: Backend Setup (PHP + MySQL)

### Step 1: Database Setup
```bash
# Open MySQL client
mysql -u root -p

# Create database
CREATE DATABASE digitrix_maha_maintain_pro;
CREATE USER 'digitrix_maha_user'@'localhost' IDENTIFIED BY 'your_secure_password';
GRANT ALL PRIVILEGES ON digitrix_maha_maintain_pro.* TO 'digitrix_maha_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### Step 2: Import Database Migrations
```bash
# From project root directory
cd database/migrations

# Import tables (in order)
mysql -u digitrix_maha_user -p digitrix_maha_maintain_pro < 001_create_cart_tables.sql
mysql -u digitrix_maha_user -p digitrix_maha_maintain_pro < 002_modify_existing_tables.sql

# Verify
mysql -u digitrix_maha_user -p digitrix_maha_maintain_pro -e "SHOW TABLES;"
```

### Step 3: Configure PHP API
```bash
# Navigate to api directory
cd api

# Create config.php (if not exists)
cp config.php.example config.php

# Edit config.php with your database credentials
nano config.php
```

**config.php template:**
```php
<?php
define('DB_HOST', 'localhost');
define('DB_USER', 'digitrix_maha_user');
define('DB_PASS', 'your_secure_password');
define('DB_NAME', 'digitrix_maha_maintain_pro');

define('JWT_SECRET', 'your_jwt_secret_key_here');

// Razorpay (for production)
define('RAZORPAY_KEY_ID', 'rzp_live_xxxxx');
define('RAZORPAY_KEY_SECRET', 'secret_xxxxx');
?>
```

### Step 4: Start PHP Development Server
```bash
# From project root
cd api

# Start server (runs on http://localhost:8000)
php -S localhost:8000

# Should see: "Development Server (http://localhost:8000) started"
```

---

## 📱 Part 2: Flutter Setup

### Step 1: Project Setup
```bash
# Navigate to project root
cd /path/to/MAHAMAINTAINPRO

# Get Flutter packages
flutter pub get

# Check Flutter setup
flutter doctor

# Fix any issues reported
```

### Step 2: Configure API Endpoint
**File: `lib/config/api_config.dart`**
```dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:8000';
  static const String apiVersion = '/api/v1';
  
  static String get fullUrl => '$baseUrl$apiVersion';
}
```

### Step 3: Generate Dart Models (Optional but Recommended)
```bash
# Install build_runner
flutter pub add build_runner
flutter pub add json_serializable

# Generate code
flutter pub run build_runner build
```

---

## 🧪 Part 3: Testing

### Run Unit Tests
```bash
# All tests
flutter test

# Specific test file
flutter test test/services/checkout_service_test.dart

# With coverage
flutter test --coverage
```

### Run Widget Tests
```bash
# All widget tests
flutter test test/widgets/

# Specific widget
flutter test test/widgets/price_breakdown_test.dart
```

### Run Integration Tests
```bash
# All integration tests
flutter test test/integration/
```

---

## 🚀 Part 4: Run the App

### On Android Emulator
```bash
# Start emulator
emulator -avd Pixel_4_API_30

# Run app
flutter run

# Or with specific device
flutter run -d emulator-5554
```

### On iOS Simulator (macOS only)
```bash
# Start simulator
open -a Simulator

# Run app
flutter run

# Or with specific device
flutter devices  # List devices
flutter run -d 'iPhone 12'
```

### On Physical Device
```bash
# Enable USB debugging on device

# Connect device
adb devices  # Android
xcrun instruments -s devices  # iOS

# Run
flutter run
```

---

## 🔍 Part 5: API Testing

### Test Endpoints with cURL

#### 1. Health Check
```bash
curl -X GET http://localhost:8000/api/health
```

#### 2. Cart Operations
```bash
# Get cart
curl -X GET http://localhost:8000/api/v1/cart \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Add item
curl -X POST http://localhost:8000/api/v1/cart/add-item \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "service_id": 1,
    "package_id": 1,
    "quantity": 1,
    "selected_addons": []
  }'
```

#### 3. Checkout Operations
```bash
# Initialize checkout
curl -X POST http://localhost:8000/api/v1/checkout/init \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "cart_id": "CART_123",
    "service_location_id": 15,
    "scheduled_date": "2026-09-30",
    "time_slot_id": 5
  }'

# Get payment order
curl -X POST http://localhost:8000/api/v1/checkout/payment-intent \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{"checkout_id": "CHECKOUT_123"}'
```

---

## 🐛 Troubleshooting

### PHP Server Issues
```bash
# Port already in use?
lsof -i :8000
kill -9 <PID>

# Enable required extensions
php -m | grep curl
php -m | grep pdo
php -m | grep json
```

### Database Connection Issues
```bash
# Test connection
mysql -u digitrix_maha_user -p digitrix_maha_maintain_pro -e "SELECT 1;"

# Check MySQL service
sudo systemctl status mysql  # Linux
brew services list | grep mysql  # macOS
```

### Flutter Issues
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub upgrade

# Run with verbose output
flutter run -v

# Check doctor
flutter doctor -v
```

### API Response Issues
```bash
# Check PHP error log
tail -f /var/log/php-errors.log

# Check PHP syntax
php -l api/v1/cart/get-cart.php

# Enable debug mode in config
define('DEBUG', true);
```

---

## ✅ Verification Checklist

### Backend Ready?
- [ ] MySQL database created
- [ ] Migrations imported successfully
- [ ] PHP server running (http://localhost:8000)
- [ ] config.php configured
- [ ] JWT secret set
- [ ] Can curl health endpoint

### Frontend Ready?
- [ ] Flutter installed (`flutter --version`)
- [ ] Dependencies installed (`flutter pub get`)
- [ ] No errors in `flutter doctor`
- [ ] API endpoint configured
- [ ] Can run tests (`flutter test`)

### Ready to Run?
- [ ] PHP server running: `php -S localhost:8000`
- [ ] MySQL running: `mysql -u root -p`
- [ ] Flutter emulator/device ready: `flutter devices`
- [ ] Run: `flutter run`

---

## 📝 Sample Data (Optional)

### Create Test User
```sql
INSERT INTO users (id, name, email, phone, is_active, created_at)
VALUES (1, 'Test User', 'test@example.com', '9773609077', 1, NOW());
```

### Create Test Service
```sql
INSERT INTO services (id, name, description, category_id, vendor_id, price, is_active, created_at)
VALUES (1, 'AC Service', 'Air Conditioning Service', 1, 1, 799.00, 1, NOW());
```

### Create Test Vendor
```sql
INSERT INTO vendors (id, name, email, phone, is_active, created_at)
VALUES (1, 'Service Provider', 'vendor@example.com', '9876543210', 1, NOW());
```

---

## 🎯 First Test: Complete Checkout Flow

### 1. Start Backend
```bash
cd api
php -S localhost:8000
# Should see: "Development Server started..."
```

### 2. Start Flutter App
```bash
flutter run

# Choose device:
# - press 'a' for Android emulator
# - press 'i' for iOS simulator
# - or select physical device
```

### 3. Test in App
1. Add service to cart
2. Go to checkout
3. Enter pincode
4. Select date & time
5. Review pricing
6. Proceed to payment (test mode)

### 4. Verify in Backend
```bash
# Check cart created
mysql> SELECT * FROM carts WHERE user_id = '9773609077';

# Check booking created
mysql> SELECT * FROM bookings ORDER BY created_at DESC LIMIT 1;

# Check order created
mysql> SELECT * FROM orders ORDER BY created_at DESC LIMIT 1;
```

---

## 📊 Expected Output

### PHP Server
```
Development Server (http://localhost:8000) started
Listening on http://localhost:8000
Press Ctrl+C to quit.
```

### Flutter App
```
Launching lib/main.dart on [Device Name]...
Running "flutter pub get"...
Running Gradle build...
✓ Built build/app/outputs/flutter-app-debug.apk (XX.XX MB)
Installing and launching...
✓ App started successfully!
```

### Tests
```
00:00 +1: All tests passed!

===========================
Test Results: 107 tests, all passing ✓
Code Coverage: 85%
===========================
```

---

## 🎉 You're Ready!

Once everything is running:

✅ **Backend API** responding on `http://localhost:8000`  
✅ **Database** storing data  
✅ **Flutter app** running on device/emulator  
✅ **Complete checkout flow** working end-to-end  
✅ **All tests** passing  

---

## 🆘 Need Help?

**Common Issues & Solutions:**

| Problem | Solution |
|---------|----------|
| PHP port 8000 in use | Use different port: `php -S localhost:8001` |
| MySQL connection failed | Check user/password in config.php |
| Flutter errors | Run `flutter doctor` and fix issues |
| API 401 Unauthorized | Get valid JWT token |
| Database migration fails | Check MySQL user has GRANT permissions |

---

## 📞 Support Commands

```bash
# Check everything
flutter doctor -v
php -v
mysql --version
git --version

# Test API
curl http://localhost:8000/health

# View logs
tail -f /var/log/php-errors.log
tail -f /var/log/mysql/error.log

# Kill processes on port
lsof -i :8000
lsof -i :3306
```

---

**Status:** Ready to Deploy Locally

**Time Expected:** 30-45 minutes for full setup
