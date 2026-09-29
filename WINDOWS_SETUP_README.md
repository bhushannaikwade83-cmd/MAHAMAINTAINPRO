# Windows Setup - Batch Files Guide

## 📦 Prerequisites

Before running any batch files, install these on Windows:

1. **PHP 7.4+** - https://www.php.net/downloads
   - Add to PATH during installation
   
2. **MySQL 5.7+** - https://dev.mysql.com/downloads/mysql/
   - Set root password during installation
   
3. **Flutter SDK** - https://flutter.dev/docs/get-started/install/windows
   - Add to PATH automatically during installation
   
4. **Git** - https://git-scm.com/
   - Use default installation

---

## 🚀 Quick Start (One Command)

```bash
SETUP_AND_RUN.bat
```

This does EVERYTHING:
- ✅ Checks prerequisites
- ✅ Creates database
- ✅ Imports migrations
- ✅ Configures PHP
- ✅ Starts PHP server
- ⏱️ ~5 minutes total

---

## 📋 Batch Files Included

### 1. **SETUP_AND_RUN.bat** (Complete Setup)
**Use this FIRST TIME only**

```bash
SETUP_AND_RUN.bat
```

**What it does:**
1. Verifies PHP, MySQL, Flutter, Git installed
2. Asks for MySQL root password
3. Creates database `digitrix_maha_maintain_pro`
4. Creates MySQL user `digitrix_maha_user`
5. Imports migration files (001, 002)
6. Creates `api/config.php`
7. Gets Flutter packages
8. **Starts PHP server** on http://localhost:8000

**Next step:** Run `RUN_APP.bat` in another window

---

### 2. **START_SERVER.bat** (Start PHP Server)
**Use to start backend server**

```bash
START_SERVER.bat
```

**What it does:**
- Starts PHP development server
- Runs on http://localhost:8000
- Shows available API endpoints
- Keep this running while developing

**Run in:** Separate terminal window

---

### 3. **RUN_APP.bat** (Run Flutter App)
**Use to start mobile app**

```bash
RUN_APP.bat
```

**What it does:**
- Lists connected devices/emulators
- Starts Flutter app
- Compiles and runs on your device

**Prerequisites:**
- PHP server running (START_SERVER.bat)
- Flutter device/emulator ready

---

### 4. **RUN_TESTS.bat** (Run Test Suite)
**Use to run tests**

```bash
RUN_TESTS.bat
```

**Menu options:**
1. Run ALL tests (107 scenarios)
2. Run unit tests only
3. Run widget tests only
4. Run integration tests only
5. Run with coverage report
6. Exit

---

## 🎯 Typical Workflow

### First Time Setup
```
1. Double-click: SETUP_AND_RUN.bat
   ↓
   Waits for MySQL root password
   ↓
   Completes setup (~5 min)
   ↓
   Starts PHP server
```

### Daily Development (Two Windows)

**Window 1:** (Keep running)
```
Double-click: START_SERVER.bat
```

**Window 2:** (Run when you want)
```
Double-click: RUN_APP.bat
```

### When You Want to Test
```
Double-click: RUN_TESTS.bat
```

---

## 🔧 Troubleshooting

### "PHP not found"
- Install PHP: https://www.php.net/downloads
- Add to PATH: https://www.php.net/manual/en/install.windows.environment.php

### "MySQL not found"
- Install MySQL: https://dev.mysql.com/downloads/mysql/
- Ensure MySQL Service is running (Services app)

### "Flutter not found"
- Install Flutter: https://flutter.dev/docs/get-started/install/windows
- Run `flutter doctor` in terminal to verify

### "Access denied" for database
- Check MySQL password is correct
- Verify MySQL service is running
- Restart MySQL service

### Port 8000 already in use
- Edit START_SERVER.bat to use different port:
  ```
  php -S localhost:8001
  ```

### Flutter emulator not found
- Open Android Studio
- Create virtual device
- Or connect physical device with USB debugging

---

## 📱 Running on Different Devices

### Android Emulator
```bash
RUN_APP.bat
# Select Android emulator from menu
```

### iPhone Simulator (macOS only)
```bash
RUN_APP.bat
# Select iPhone simulator from menu
```

### Physical Android Phone
```bash
# Connect with USB cable
# Enable USB debugging in Developer Options
RUN_APP.bat
# Select your device from menu
```

---

## 🧪 Test Examples

### Run All Tests
```
RUN_TESTS.bat
Select: 1
Result: 107 tests run
```

### Run Unit Tests
```
RUN_TESTS.bat
Select: 2
Result: Service tests only
```

### Generate Coverage Report
```
RUN_TESTS.bat
Select: 5
Result: Report in coverage/lcov.info
```

---

## ✅ Expected Output

### SETUP_AND_RUN.bat
```
============================================================================
 MahaMaintain Pro - Complete Setup & Run
============================================================================

[1/6] Checking prerequisites...
[OK] PHP 8.1 installed
[OK] MySQL installed
[OK] Flutter 3.x installed
[OK] Git installed

[2/6] Setting up Database
Enter MySQL root password: ****

[OK] Database and user created

Importing 001_create_cart_tables.sql...
[OK] Migration 001 imported

Importing 002_modify_existing_tables.sql...
[OK] Migration 002 imported (or already exists)

Configuring PHP API...
[OK] config.php created

Getting Flutter packages...
[OK] Flutter packages ready

[6/6] Starting Servers
[SUCCESS] Setup complete!

============================================================================
STARTING BACKEND SERVER
============================================================================

Server starting on http://localhost:8000
Press Ctrl+C to stop

[Thu Sep 29 12:00:00 2026] PHP 8.1 Development Server started
[Thu Sep 29 12:00:00 2026] Listening on http://localhost:8000
[Thu Sep 29 12:00:01 2026] Accepted connections from 127.0.0.1:12345
```

### START_SERVER.bat
```
============================================================================
 MahaMaintain Pro - Start PHP Server
============================================================================

[OK] PHP is installed

Starting PHP development server...

Server will run on: http://localhost:8000

API Endpoints:
  - GET    http://localhost:8000/api/v1/cart
  - POST   http://localhost:8000/api/v1/cart/add-item
  - POST   http://localhost:8000/api/v1/checkout/init
  ...

Press Ctrl+C to stop the server

============================================================================

[Thu Sep 29 12:00:00 2026] PHP 8.1 Development Server started
```

### RUN_APP.bat
```
============================================================================
 MahaMaintain Pro - Run Flutter App
============================================================================

[OK] Flutter ready

Available devices:
Android SDK built for arm64 (mobile) • emulator-5554 • android-arm64 • Android 14 (API 34) (emulator)
Pixel 4a 5G (mobile)                  • 07ac51b8      • android-arm64 • Android 14

Starting Flutter app...
Press Ctrl+C to stop

Building for Android...
...
✓ Built build/app/outputs/flutter-app-debug.apk
Installing and launching...
✓ App started successfully!
```

---

## 🚀 First Run Checklist

- [ ] Prerequisites installed (PHP, MySQL, Flutter, Git)
- [ ] SETUP_AND_RUN.bat runs without errors
- [ ] MySQL root password entered correctly
- [ ] Migrations imported successfully
- [ ] PHP server started on http://localhost:8000
- [ ] RUN_APP.bat selected a device
- [ ] Flutter app installed and launched
- [ ] App appears on screen
- [ ] Can navigate and test features

---

## 📞 Command Reference

```bash
# Complete setup (one time)
SETUP_AND_RUN.bat

# Start server (keep running)
START_SERVER.bat

# Run app (in new window)
RUN_APP.bat

# Run tests
RUN_TESTS.bat

# Manual commands if needed
php -S localhost:8000              # Start PHP
flutter run                        # Run app
flutter test                       # Run tests
flutter pub get                    # Get packages
flutter doctor                     # Check setup
```

---

## 🎯 Success Indicators

✅ PHP server running on http://localhost:8000  
✅ Flutter app displayed on device/emulator  
✅ Can add items to cart  
✅ Can proceed to checkout  
✅ All tests pass (107/107)  

---

## 📝 Notes

- Keep START_SERVER.bat running in background
- You can have multiple RUN_APP.bat windows for different devices
- Tests run independently, don't need server running
- Ctrl+C stops any batch file
- All batch files auto-detect issues and show helpful errors

---

**Everything is ready to go! Just double-click SETUP_AND_RUN.bat to start.** 🚀
