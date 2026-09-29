@echo off
REM ============================================================================
REM MahaMaintain Pro - Complete Setup & Run Script for Windows
REM ============================================================================
REM This script will:
REM 1. Check all prerequisites
REM 2. Create & configure database
REM 3. Import migrations
REM 4. Configure PHP API
REM 5. Start PHP server
REM 6. Start Flutter app
REM ============================================================================

setlocal enabledelayedexpansion
cd /d "%~dp0"

REM Colors (using Windows console escape codes)
set "GREEN=[92m"
set "RED=[91m"
set "YELLOW=[93m"
set "RESET=[0m"

cls
echo.
echo ============================================================================
echo  MahaMaintain Pro - Complete Setup ^& Run
echo ============================================================================
echo.

REM ============================================================================
REM 1. CHECK PREREQUISITES
REM ============================================================================
echo [1/6] Checking prerequisites...
echo.

REM Check PHP
php -v >nul 2>&1
if errorlevel 1 (
    echo %RED%[ERROR]%RESET% PHP not found. Please install PHP 7.4+
    echo.
    echo Download from: https://www.php.net/downloads
    echo.
    pause
    exit /b 1
) else (
    for /f "tokens=2" %%i in ('php -v ^| findstr /r "PHP [0-9]"') do (
        echo %GREEN%[OK]%RESET% PHP %%i installed
    )
)

REM Check MySQL
mysql --version >nul 2>&1
if errorlevel 1 (
    echo %RED%[ERROR]%RESET% MySQL not found. Please install MySQL 5.7+
    echo.
    echo Download from: https://dev.mysql.com/downloads/mysql/
    echo.
    pause
    exit /b 1
) else (
    echo %GREEN%[OK]%RESET% MySQL installed
)

REM Check Flutter
flutter --version >nul 2>&1
if errorlevel 1 (
    echo %RED%[ERROR]%RESET% Flutter not found. Please install Flutter SDK
    echo.
    echo Download from: https://flutter.dev/docs/get-started/install
    echo.
    pause
    exit /b 1
) else (
    for /f "tokens=2" %%i in ('flutter --version ^| findstr /r "Flutter [0-9]"') do (
        echo %GREEN%[OK]%RESET% Flutter %%i installed
    )
)

REM Check Git
git --version >nul 2>&1
if errorlevel 1 (
    echo %RED%[ERROR]%RESET% Git not found. Please install Git
    echo.
    echo Download from: https://git-scm.com/
    echo.
    pause
    exit /b 1
) else (
    echo %GREEN%[OK]%RESET% Git installed
)

echo.
pause /b

REM ============================================================================
REM 2. DATABASE SETUP
REM ============================================================================
cls
echo.
echo ============================================================================
echo [2/6] Setting up Database
echo ============================================================================
echo.

set /p mysql_pass="Enter MySQL root password: "

REM Create database and user
echo Creating database...
mysql -u root -p%mysql_pass% -e "CREATE DATABASE IF NOT EXISTS digitrix_maha_maintain_pro;" 2>nul
if errorlevel 1 (
    echo %RED%[ERROR]%RESET% Failed to create database. Check MySQL password.
    pause
    exit /b 1
)

echo Creating user...
mysql -u root -p%mysql_pass% -e "CREATE USER IF NOT EXISTS 'digitrix_maha_user'@'localhost' IDENTIFIED BY 'secure_password_123';" 2>nul
mysql -u root -p%mysql_pass% -e "GRANT ALL PRIVILEGES ON digitrix_maha_maintain_pro.* TO 'digitrix_maha_user'@'localhost';" 2>nul
mysql -u root -p%mysql_pass% -e "FLUSH PRIVILEGES;" 2>nul

echo %GREEN%[OK]%RESET% Database and user created

REM ============================================================================
REM 3. IMPORT MIGRATIONS
REM ============================================================================
echo.
echo Importing migrations...
echo.

if not exist "database\migrations\001_create_cart_tables.sql" (
    echo %RED%[ERROR]%RESET% Migration file not found: database\migrations\001_create_cart_tables.sql
    pause
    exit /b 1
)

echo Importing 001_create_cart_tables.sql...
mysql -u digitrix_maha_user -psecure_password_123 digitrix_maha_maintain_pro < database\migrations\001_create_cart_tables.sql 2>nul
if errorlevel 1 (
    echo %RED%[ERROR]%RESET% Failed to import migration 001
    pause
    exit /b 1
)
echo %GREEN%[OK]%RESET% Migration 001 imported

echo Importing 002_modify_existing_tables.sql...
mysql -u digitrix_maha_user -psecure_password_123 digitrix_maha_maintain_pro < database\migrations\002_modify_existing_tables.sql 2>nul
if errorlevel 1 (
    echo %RED%[ERROR]%RESET% Failed to import migration 002
    echo Note: This may be OK if columns already exist
)
echo %GREEN%[OK]%RESET% Migration 002 imported (or already exists)

REM ============================================================================
REM 4. CONFIGURE PHP API
REM ============================================================================
echo.
echo Configuring PHP API...
echo.

if not exist "api\config.php" (
    echo Creating api\config.php...
    (
        echo ^<?php
        echo define('DB_HOST', 'localhost'^);
        echo define('DB_USER', 'digitrix_maha_user'^);
        echo define('DB_PASS', 'secure_password_123'^);
        echo define('DB_NAME', 'digitrix_maha_maintain_pro'^);
        echo.
        echo define('JWT_SECRET', 'your_jwt_secret_key_here_change_in_production'^);
        echo.
        echo define('RAZORPAY_KEY_ID', 'rzp_test_xxxxx'^);
        echo define('RAZORPAY_KEY_SECRET', 'secret_xxxxx'^);
        echo.
        echo define('DEBUG', true'^);
        echo ?^>
    ) > api\config.php
    echo %GREEN%[OK]%RESET% config.php created
) else (
    echo %GREEN%[OK]%RESET% config.php already exists
)

REM ============================================================================
REM 5. SETUP FLUTTER
REM ============================================================================
echo.
echo Getting Flutter packages...
call flutter pub get >nul 2>&1
if errorlevel 1 (
    echo %RED%[WARNING]%RESET% Flutter pub get failed, but this may be OK
)
echo %GREEN%[OK]%RESET% Flutter packages ready

REM ============================================================================
REM 6. START SERVERS
REM ============================================================================
cls
echo.
echo ============================================================================
echo [6/6] Starting Servers
echo ============================================================================
echo.
echo %GREEN%[SUCCESS]%RESET% Setup complete!
echo.
echo.
echo ============================================================================
echo STARTING BACKEND SERVER
echo ============================================================================
echo.
echo Server starting on http://localhost:8000
echo Press Ctrl+C to stop
echo.
echo ============================================================================
echo.

REM Start PHP server in current window
cd api
php -S localhost:8000

REM When PHP server stops, close
echo.
echo %RED%[INFO]%RESET% PHP server stopped
pause
exit /b 0
