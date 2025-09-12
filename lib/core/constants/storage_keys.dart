/// Storage keys used throughout the application
class StorageKeys {
  // App settings
  static const String appTheme = 'app_theme';
  static const String appLanguage = 'app_language';
  static const String isFirstLaunch = 'is_first_launch';
  
  // User preferences
  static const String lastSyncTime = 'last_sync_time';
  static const String sortPreference = 'sort_preference';
  static const String defaultTab = 'default_tab';
  
  // App state
  static const String lastOpenedStatus = 'last_opened_status';
  static const String downloadLocation = 'download_location';
  
  // Feature flags
  static const String isAutoSaveEnabled = 'is_auto_save_enabled';
  static const String isAppLockEnabled = 'is_app_lock_enabled';
  static const String isAnalyticsEnabled = 'is_analytics_enabled';
  
  // App data
  static const String savedStatuses = 'saved_statuses';
  static const String favoriteStatuses = 'favorite_statuses';
  static const String hiddenStatuses = 'hidden_statuses';
  
  // User data
  static const String userId = 'user_id';
  static const String userName = 'user_name';
  static const String userEmail = 'user_email';
  static const String userProfilePic = 'user_profile_pic';
  
  // App configuration
  static const String appConfig = 'app_config';
  static const String lastAppVersion = 'last_app_version';
  
  // Don't allow instantiation
  const StorageKeys._();
}
