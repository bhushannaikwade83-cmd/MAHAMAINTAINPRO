/// Global, non-environment-specific constants for the app.
class AppConstants {
  AppConstants._();

  static const String appName = 'Maha Maintain Pro';

  // Firestore collection names — centralised so a rename only happens once.
  static const String usersCollection = 'users';
  static const String leadsCollection = 'leads';
  static const String customersCollection = 'customers';
  static const String societiesCollection = 'societies';
  static const String serviceRequestsCollection = 'service_requests';
  static const String workOrdersCollection = 'work_orders';
  static const String activityLogCollection = 'activity_logs';

  // Secure storage keys
  static const String storageKeyAuthToken = 'auth_token';
  static const String storageKeyUserId = 'user_id';
  static const String storageKeyUserRole = 'user_role';
  static const String storageKeyRefreshToken = 'refresh_token';

  // Pagination
  static const int defaultPageSize = 20;

  // OTP
  static const int otpLength = 6;
  static const int otpResendSeconds = 30;
}
