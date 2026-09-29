@echo off
REM ============================================================================
REM MahaMaintain Pro - Run Flutter App Only
REM (Use this after initial setup)
REM ============================================================================
REM Prerequisites:
REM - Run SETUP_AND_RUN.bat first (one time)
REM - Make sure PHP server is running (run START_SERVER.bat in another window)
REM ============================================================================

setlocal enabledelayedexpansion
cd /d "%~dp0"

cls
echo.
echo ============================================================================
echo  MahaMaintain Pro - Run Flutter App
echo ============================================================================
echo.

REM Check Flutter
flutter --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Flutter not found
    echo Please install Flutter first: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo [OK] Flutter ready
echo.

REM Check if device available
echo Available devices:
flutter devices
echo.

echo Starting Flutter app...
echo Press Ctrl+C to stop
echo.

call flutter run

pause
exit /b 0
