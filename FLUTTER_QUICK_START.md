# Flutter App - Quick Start Guide

## What's Been Done
Your Android Kotlin app has been **completely converted to Flutter** with the same UI, screens, and functionality:
- ✅ Login screen (phone OTP)
- ✅ OTP verification screen
- ✅ Dashboard screen (properties & transactions)
- ✅ Supabase authentication & database
- ✅ Razorpay payment integration
- ✅ Firebase messaging setup
- ✅ Full color scheme (Saffron, Gold, Teal)

## File Location
```
/Users/bhushan/Desktop/PROJECTS/maha-maintanpro-main/flutter_app/
```

## Quick Setup (5 minutes)

### 1. Install Dependencies
```bash
cd flutter_app
flutter pub get
```

### 2. Add Your Credentials

**File: `lib/config/supabase_config.dart`**
```dart
static const String supabaseUrl = 'https://your-project.supabase.co';
static const String supabaseAnonKey = 'your-anon-key';
```

**File: `lib/repositories/payment_repository.dart`**
```dart
String razorpayKeyId = 'rzp_live_YOUR_KEY_HERE',
```

**File: `lib/services/firebase_options.dart`**
- Update Android, iOS, and Web configuration

### 3. Create Supabase Tables
Run these SQL commands in your Supabase dashboard:

```sql
-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_number VARCHAR(20) UNIQUE,
  name VARCHAR(255),
  email VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Properties table
CREATE TABLE properties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  address TEXT,
  latitude FLOAT,
  longitude FLOAT,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Transactions table
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  property_id UUID REFERENCES properties(id) ON DELETE SET NULL,
  amount DECIMAL(10, 2) NOT NULL,
  description TEXT,
  status VARCHAR(50) DEFAULT 'pending',
  type VARCHAR(50),
  payment_id VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Enable RLS (Row Level Security)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
```

### 4. Run the App
```bash
flutter run
```

## Project Structure
```
flutter_app/lib/
├── config/              # Theme, Router, Supabase config
├── repositories/        # Auth, Database, Payment logic
├── screens/            # Login, OTP, Dashboard
├── models/             # User, Property, Transaction data classes
├── services/           # Firebase setup
└── main.dart          # App entry point
```

## Key Screens

### 1. Login Screen (`login_screen.dart`)
- Phone number input (10 digits)
- Send OTP button
- Error handling

### 2. OTP Screen (`otp_screen.dart`)
- 6-digit OTP input
- Verify button
- Resend OTP (30-sec cooldown)
- Change phone number option

### 3. Dashboard Screen (`dashboard_screen.dart`)
- Welcome card
- Properties list
- Transactions list
- Logout button

## Testing the Flows

### Test Authentication
1. Enter phone number (test: 9876543210)
2. Click "Send OTP"
3. Verify OTP (get from Supabase logs)
4. You should see Dashboard

### Test Dashboard
- Properties and transactions display data from Supabase
- Add test data via Supabase dashboard

### Test Payments
- Use Razorpay test keys
- Integration ready in `PaymentRepository`

## Comparison: Android → Flutter

| Feature | Android | Flutter |
|---------|---------|---------|
| Language | Kotlin | Dart |
| UI Framework | Jetpack Compose | Flutter Widgets |
| Auth | Supabase SDK | supabase_flutter |
| Payments | razorpay-android | razorpay_flutter |
| Notifications | Firebase FCM | firebase_messaging |
| Navigation | Compose Navigation | go_router |
| State Management | MutableState | Riverpod |
| Database | Supabase | supabase_flutter |

## Colors Used
```dart
Primary:   #F25C05 (Saffron)
Secondary: #E5A100 (Gold)
Accent:    #00A693 (Teal)
```

## Dependencies Added
```yaml
supabase_flutter: ^2.0.0
razorpay_flutter: ^1.3.10
firebase_core: ^3.1.0
firebase_messaging: ^15.1.0
go_router: ^14.0.0
riverpod: ^2.4.0
flutter_riverpod: ^2.4.0
```

## Common Commands

```bash
# Install dependencies
flutter pub get

# Run app
flutter run

# Build APK (Android)
flutter build apk --release

# Build IPA (iOS)
flutter build ios --release

# Clean build
flutter clean
flutter pub get
flutter run

# Check code issues
flutter analyze

# Format code
flutter format lib/
```

## Debugging Tips

1. **Supabase Connection Issues**
   - Check URL and API key in `supabase_config.dart`
   - Verify network connectivity
   - Check Supabase logs

2. **Firebase Issues**
   - Ensure google-services.json is in `android/app/`
   - Ensure GoogleService-Info.plist is in `ios/Runner/`
   - Restart the app after Firebase setup

3. **Razorpay Issues**
   - Use test key for development
   - Check payment amount is in paise (multiply by 100)
   - Verify Razorpay account is active

4. **App Crashes**
   - Check Flutter logs: `flutter logs`
   - Check Dart analysis: `flutter analyze`
   - Verify all imports are correct

## Next Steps

1. ✅ Install dependencies
2. ✅ Add Supabase credentials
3. ✅ Create database tables
4. ✅ Add Firebase credentials
5. ✅ Add Razorpay credentials
6. ✅ Run on emulator/device
7. ✅ Test authentication flow
8. ✅ Test dashboard
9. ✅ Build for production
10. ✅ Deploy to Play Store/App Store

## Documentation Links
- Flutter: https://flutter.dev/docs
- Supabase: https://supabase.io/docs/reference/dart
- Razorpay: https://razorpay.com/docs/api/orders/
- Firebase: https://firebase.google.com/docs/flutter/setup
- GoRouter: https://pub.dev/packages/go_router
- Riverpod: https://riverpod.dev

---

**Questions?** Check `FLUTTER_MIGRATION_GUIDE.md` for detailed information.
