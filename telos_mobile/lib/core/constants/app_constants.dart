class AppConstants {
  static const String appName = 'TELOS';
  static const String appTagline = 'Master Your Focus, Tracks & Long-Term Goals';

  // Network Configuration
  // 10.0.2.2 is Android emulator's loopback to host localhost
  static const String baseUrl = 'http://10.0.2.2:5000/api/v1';
  static const String socketUrl = 'http://10.0.2.2:5000';

  // Storage Keys
  static const String keyToken = 'telos_auth_token';
  static const String keyUser = 'telos_user_data';
  static const String keyTheme = 'telos_theme_mode';
  static const String keyLanguage = 'telos_language';

  // Recurrence Types
  static const String repeatNone = 'none';
  static const String repeatDaily = 'daily';
  static const String repeatWeekdays = 'weekdays';
  static const String repeatWeekly = 'weekly';
  static const String repeatMonthly = 'monthly';
  static const String repeatUntilComplete = 'repeat_until_completed';
}
