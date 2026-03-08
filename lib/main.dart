import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'views/theme/app_theme.dart';
import 'views/login/login_screen.dart';
import 'views/admin/admin_setup_screen.dart';
import 'data/db/database_helper.dart';
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

  runApp(MyApp(hasAdmin: hasAdmin));
}

class MyApp extends StatelessWidget {
  final bool hasAdmin;

  const MyApp({super.key, required this.hasAdmin});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PHR App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: hasAdmin ? const LoginScreen() : const AdminSetupScreen(),
    );
  }
}
