class AppRoutes {
  // Auth Routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Main Route (Tab Navigation)
  static const String home = '/home'; // ← NEU! Hauptroute mit BottomNav

  // Memorial Routes
  static const String memorialDetail = '/memorial-detail';
  static const String memorialCreate = '/memorial-create';
  static const String memorialEdit = '/memorial/edit';
  static const String pageBuilder = '/page-builder';

  // Invitation Route
  static const String inviteRedeem = '/invite';

  // Profile Routes
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String about = '/about';

  // Utility
  static const String notFound = '/404';
}
