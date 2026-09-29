@echo off
REM ============================================================================
REM MahaMaintain Pro - Run Tests
REM ============================================================================

setlocal enabledelayedexpansion
cd /d "%~dp0"

cls
echo.
echo ============================================================================
echo  MahaMaintain Pro - Run Tests
echo ============================================================================
echo.

REM Check Flutter
flutter --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Flutter not found
    pause
    exit /b 1
)

echo Updating packages...
call flutter pub get >nul 2>&1

echo.
echo ============================================================================
echo Choose test type:
echo ============================================================================
echo.
echo 1. Run ALL tests
echo 2. Run unit tests only
echo 3. Run widget tests only
echo 4. Run integration tests only
echo 5. Run tests with coverage
echo 6. Exit
echo.

set /p choice="Enter choice (1-6): "

if "%choice%"=="1" (
    echo.
    echo Running all tests...
    echo.
    call flutter test
) else if "%choice%"=="2" (
    echo.
    echo Running unit tests...
    echo.
    call flutter test test/services/
) else if "%choice%"=="3" (
    echo.
    echo Running widget tests...
    echo.
    call flutter test test/widgets/
) else if "%choice%"=="4" (
    echo.
    echo Running integration tests...
    echo.
    call flutter test test/integration/
) else if "%choice%"=="5" (
    echo.
    echo Running tests with coverage...
    echo.
    call flutter test --coverage
    echo.
    echo Coverage report generated in: coverage/lcov.info
) else if "%choice%"=="6" (
    exit /b 0
) else (
    echo Invalid choice
)

echo.
pause
exit /b 0
