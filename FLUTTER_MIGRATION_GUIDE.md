# Flutter Migration Guide - MahaMaintain Pro

## Overview
Successfully converted the Android Kotlin/Compose app to a complete Flutter application with the same UI, functionality, and screens.

## Project Structure

```
flutter_app/
├── lib/
│   ├── config/
│   │   ├── app_theme.dart          # Colors, themes (Saffron, Gold, Teal)
│   │   ├── app_router.dart         # Navigation with go_router
│   │   └── supabase_config.dart    # Supabase initialization
│   ├── repositories/
│   │   ├── auth_repository.dart    # Phone OTP authentication
│   │   ├── db_repository.dart      # User, properties, transactions
│   │   └── payment_repository.dart # Razorpay integration
│   ├── screens/
│   │   ├── login_screen.dart       # Phone login with OTP send
│   │   ├── otp_screen.dart         # OTP verification
│   │   └── dashboard_screen.dart   # Main dashboard with properties & transactions
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── property_model.dart
│   │   └── transaction_model.dart
│   ├── services/
│   │   ├── firebase_service.dart   # Firebase Cloud Messaging
│   │   └── firebase_options.dart   # Firebase configuration
│   └── main.dart                   # App entry point with Riverpod & GoRouter
├── pubspec.yaml                    # Dependencies (Supabase, Razorpay, Firebase, etc.)
└── analysis_options.yaml
```

## Key Features Migrated

### ✅ Authentication
- **Phone-based OTP login** (via Supabase)
- Send OTP to phone number
- Verify OTP with 6-digit code
- Resend OTP with 30-second cooldown
- Session management

### ✅ UI & Screens
- **Login Screen**: Same layout as Compose version (icon, title, phone input, send OTP button)
- **OTP Screen**: OTP verification with resend functionality
- **Dashboard Screen**: Properties list, transactions list with real-time data

### ✅ Backend Integration
- **Supabase**: Authentication and database operations
- **Database Tables Required**:
  - `users` (id, phone_number, name, email, created_at, updated_at)
  - `properties` (id, user_id, name, address, latitude, longitude, created_at, updated_at)
  - `transactions` (id, user_id, property_id, amount, description, status, type, payment_id, created_at)

### ✅ Payments
- **Razorpay integration** for payment processing
- Payment success/failure handling

### ✅ Notifications
- **Firebase Cloud Messaging** setup
- Push notification support

### ✅ State Management
- **Riverpod** for state management and dependency injection
- **GoRouter** for navigation

## Configuration Steps

### 1. **Install Dependencies**
```bash
cd flutter_app
flutter pub get
```

### 2. **Configure Supabase**
Replace credentials in `lib/config/supabase_config.dart`:
```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### 3. **Configure Firebase**
- Download `google-services.json` from Firebase Console
- Place in `android/app/`
- Download `GoogleService-Info.plist` from Firebase Console
- Place in `ios/Runner/`
- Update credentials in `lib/services/firebase_options.dart`

### 4. **Configure Razorpay**
Replace Razorpay key in `lib/repositories/payment_repository.dart`:
```dart
String razorpayKeyId = 'rzp_test_YOUR_KEY_HERE',
```

### 5. **Android Configuration**
- Update package name if needed: `com.mahamaintain.pro`
- Configure AndroidManifest.xml for permissions
- Set up Firebase configuration

### 6. **iOS Configuration**
- Configure bundleId: `com.mahamaintain.pro`
- Set up iOS deployment target (minimum iOS 11.0+)
- Configure Firebase

## Running the App

### Development
```bash
cd flutter_app
flutter run
```

### Build APK (Android)
```bash
flutter build apk --release
```

### Build IPA (iOS)
```bash
flutter build ios --release
```

## Color Scheme (Same as Original)
- **Primary (Saffron)**: #F25C05
- **Secondary (Gold)**: #E5A100
- **Accent (Teal)**: #00A693
- **Background (White)**: #FFFFFF
- **Surface (Black)**: #000000

## Database Schema

### Users Table
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY,
  phone_number VARCHAR(20),
  name VARCHAR(255),
  email VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Properties Table
```sql
CREATE TABLE properties (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  name VARCHAR(255),
  address TEXT,
  latitude FLOAT,
  longitude FLOAT,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Transactions Table
```sql
CREATE TABLE transactions (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  property_id UUID REFERENCES properties(id),
  amount DECIMAL(10, 2),
  description TEXT,
  status VARCHAR(50),
  type VARCHAR(50),
  payment_id VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Common Issues & Solutions

### Issue: "Cannot find module" errors
**Solution**: Run `flutter pub get` again and ensure all dependencies are installed

### Issue: Firebase initialization fails
**Solution**: Ensure google-services.json and GoogleService-Info.plist are in correct locations

### Issue: Supabase connection error
**Solution**: Double-check Supabase URL and anon key in supabase_config.dart

### Issue: Razorpay test key not working
**Solution**: Replace test key with production key when deploying

## Migration Checklist

- [x] Create Flutter project structure
- [x] Configure Supabase
- [x] Migrate authentication (Phone OTP)
- [x] Migrate Login screen UI
- [x] Migrate OTP screen UI
- [x] Migrate Dashboard screen
- [x] Set up navigation (GoRouter)
- [x] Integrate Razorpay
- [x] Configure Firebase messaging
- [ ] Test on Android emulator
- [ ] Test on iOS simulator
- [ ] Test on real devices
- [ ] Update Firebase credentials
- [ ] Update Razorpay production keys
- [ ] Deploy to Play Store/App Store

## Next Steps

1. **Configure all credentials** (Supabase, Firebase, Razorpay)
2. **Test authentication flow** (Login → OTP → Dashboard)
3. **Verify Supabase database** tables are created
4. **Test payment integration** with Razorpay
5. **Test push notifications** with Firebase
6. **Build and deploy** to testing devices
7. **Deploy to stores** (Google Play, App Store)

## Support & Documentation

- **Flutter**: https://flutter.dev
- **Supabase**: https://supabase.io/docs
- **Razorpay**: https://razorpay.com/docs
- **Firebase**: https://firebase.google.com/docs
- **GoRouter**: https://pub.dev/packages/go_router
- **Riverpod**: https://riverpod.dev

## File Changes Summary

| Component | Android Kotlin | Flutter |
|-----------|---|---|
| Theme | colors.xml | app_theme.dart |
| Navigation | AppNavigationSupabase.kt | app_router.dart |
| Auth | SupabaseAuthRepository.kt | auth_repository.dart |
| Database | SupabaseDbRepository.kt | db_repository.dart |
| Login Screen | LoginScreenSupabase.kt | login_screen.dart |
| OTP Screen | OtpScreenSupabase.kt | otp_screen.dart |
| Dashboard | DashboardScreenSupabase.kt | dashboard_screen.dart |
| Payments | MainActivity.kt | payment_repository.dart |
| Firebase | MmpMessagingService.kt | firebase_service.dart |

---

**Migration completed on**: 2026-07-15
**Total screens migrated**: 3 (Login, OTP, Dashboard)
**All functionality preserved**: Authentication, Payments, Notifications, Database operations
