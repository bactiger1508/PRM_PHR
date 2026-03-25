import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:phrprmgroupproject/views/admin/admin_dashboard_screen.dart';
import 'package:phrprmgroupproject/views/customer/family_home_screen.dart';
import 'package:phrprmgroupproject/views/staff/staff_dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'views/theme/app_theme.dart';
import 'views/login/login_screen.dart';
import 'views/admin/admin_setup_screen.dart';
import 'data/db/database_helper.dart';
import 'data/implementations/auth_repository_impl.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'package:flutter/foundation.dart'; // Import for kDebugMode

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // In debug mode, clear the static database instance to ensure a fresh connection on hot restart.
  if (kDebugMode) {
    DatabaseHelper.clearStaticDatabaseInstance();
  }

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Check if an admin account exists
  final dbHelper = DatabaseHelper.instance;
  final bool hasAdmin = await dbHelper.hasAdminAccount();

  final prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final bool isCustomer = prefs.getBool('isCustomer') ?? true;
  final String userRole = prefs.getString('userRole') ?? '';

  // [BUG FIX] Restore user session from DB to avoid null currentUser crash
  if (isLoggedIn) {
    final userId = prefs.getInt('userId');
    if (userId != null) {
      try {
        final user = await AuthRepositoryImpl().findById(userId);
        if (user != null) {
          AuthViewModel.instance.refreshCurrentUser(user);
        } else {
          // User was deleted from DB → clear stale session
          await prefs.remove('isLoggedIn');
          await prefs.remove('userId');
          await prefs.remove('userRole');
          await prefs.remove('isCustomer');
          isLoggedIn = false;
        }
      } catch (_) {
        // DB error → force re-login
        isLoggedIn = false;
      }
    } else {
      // No userId saved → force re-login
      isLoggedIn = false;
    }
  }

  runApp(MyApp(
    hasAdmin: hasAdmin,
    isLoggedIn: isLoggedIn,
    isCustomer: isCustomer,
    userRole: userRole,
  ));
}

class MyApp extends StatelessWidget {
  final bool hasAdmin;
  final bool isLoggedIn;
  final bool isCustomer;
  final String userRole;

  const MyApp({
    super.key,
    required this.hasAdmin,
    required this.isLoggedIn,
    required this.isCustomer,
    required this.userRole
  });

  Widget _getInitialScreen() {
    if (!hasAdmin) {
      return const AdminSetupScreen();
    }

    if (isLoggedIn) {
      if (isCustomer) {
        return const CustomerFamilyHomeScreen();
      } else if (userRole == 'ADMIN') {
        return const AdminDashboardScreen();
      } else {
        return const StaffDashboardScreen();
      }
    }
    return const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PHR App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('vi', 'VN'),
      // home: hasAdmin ? const LoginScreen() : const AdminSetupScreen(),
      home: _getInitialScreen(),
    );
  }
}
