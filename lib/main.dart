import 'package:flutter/material.dart';
import 'views/dev/dev_menu_screen.dart';
import 'views/theme/app_theme.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PHR App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Set DevMenuScreen as the starting page for easy UI development
      home: const DevMenuScreen(),
    );
  }
}
