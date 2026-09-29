#!/bin/bash

# MahaMaintain Pro - Quick Start Script
# Run this to set up and start the entire project locally

set -e

echo "🚀 MahaMaintain Pro - Local Setup"
echo "=================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Check prerequisites
echo "Checking prerequisites..."
echo ""

# Check PHP
if ! command -v php &> /dev/null; then
    print_error "PHP not found. Please install PHP 7.4+"
    exit 1
fi
print_status "PHP $(php -v | head -1)"

# Check MySQL
if ! command -v mysql &> /dev/null; then
    print_error "MySQL not found. Please install MySQL 5.7+"
    exit 1
fi
print_status "MySQL found"

# Check Flutter
if ! command -v flutter &> /dev/null; then
    print_error "Flutter not found. Please install Flutter SDK"
    exit 1
fi
print_status "Flutter $(flutter --version)"

# Check Git
if ! command -v git &> /dev/null; then
    print_error "Git not found. Please install Git"
    exit 1
fi
print_status "Git $(git --version)"

echo ""
echo "=================================="
echo "Setting up Database..."
echo "=================================="
echo ""

# Database setup
read -p "MySQL root password: " -s mysql_root_pass
echo ""

# Create database and user
mysql -u root -p"$mysql_root_pass" <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS digitrix_maha_maintain_pro;
CREATE USER IF NOT EXISTS 'digitrix_maha_user'@'localhost' IDENTIFIED BY 'secure_password_123';
GRANT ALL PRIVILEGES ON digitrix_maha_maintain_pro.* TO 'digitrix_maha_user'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

print_status "Database created"

# Import migrations
echo ""
echo "Importing database migrations..."
echo ""

mysql -u digitrix_maha_user -psecure_password_123 digitrix_maha_maintain_pro < database/migrations/001_create_cart_tables.sql
print_status "Migration 001 imported"

mysql -u digitrix_maha_user -psecure_password_123 digitrix_maha_maintain_pro < database/migrations/002_modify_existing_tables.sql
print_status "Migration 002 imported"

# Create config.php
echo ""
echo "=================================="
echo "Configuring API..."
echo "=================================="
echo ""

if [ ! -f "api/config.php" ]; then
    cat > api/config.php <<'PHP_CONFIG'
<?php
define('DB_HOST', 'localhost');
define('DB_USER', 'digitrix_maha_user');
define('DB_PASS', 'secure_password_123');
define('DB_NAME', 'digitrix_maha_maintain_pro');

define('JWT_SECRET', 'your_jwt_secret_key_here_change_in_production');

define('RAZORPAY_KEY_ID', 'rzp_test_xxxxx');
define('RAZORPAY_KEY_SECRET', 'secret_xxxxx');

define('DEBUG', true);
?>
PHP_CONFIG
    print_status "config.php created"
else
    print_info "config.php already exists"
fi

# Setup Flutter
echo ""
echo "=================================="
echo "Setting up Flutter..."
echo "=================================="
echo ""

cd "$(dirname "$0")"
flutter pub get
print_status "Flutter packages installed"

flutter doctor
print_status "Flutter setup verified"

echo ""
echo "=================================="
echo "Setup Complete!"
echo "=================================="
echo ""

print_info "To start the backend server:"
echo "  cd api"
echo "  php -S localhost:8000"
echo ""

print_info "To start the Flutter app (in new terminal):"
echo "  flutter run"
echo ""

print_info "To run tests:"
echo "  flutter test"
echo ""

print_info "For detailed setup guide:"
echo "  See LOCAL_SETUP_GUIDE.md"
echo ""

print_status "Ready to go! 🎉"
