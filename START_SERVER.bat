@echo off
REM ============================================================================
REM MahaMaintain Pro - Start PHP Server Only
REM (Run this in a separate window to keep server running)
REM ============================================================================

setlocal enabledelayedexpansion
cd /d "%~dp0"

cls
echo.
echo ============================================================================
echo  MahaMaintain Pro - Start PHP Server
echo ============================================================================
echo.

REM Check PHP
php -v >nul 2>&1
if errorlevel 1 (
    echo [ERROR] PHP not found
    echo Please install PHP first: https://www.php.net/downloads
    pause
    exit /b 1
)

echo [OK] PHP is installed
echo.
echo Starting PHP development server...
echo.
echo Server will run on: http://localhost:8000
echo.
echo API Endpoints:
echo   - GET    http://localhost:8000/api/v1/cart
echo   - POST   http://localhost:8000/api/v1/cart/add-item
echo   - POST   http://localhost:8000/api/v1/checkout/init
echo   - POST   http://localhost:8000/api/v1/checkout/payment-intent
echo   - POST   http://localhost:8000/api/v1/checkout/verify-payment
echo.
echo Press Ctrl+C to stop the server
echo.
echo ============================================================================
echo.

cd api
php -S localhost:8000

echo.
echo Server stopped.
pause
exit /b 0
