import 'package:flutter/material.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../theme/app_theme.dart';
import '../staff/family_home_screen.dart';
import '../staff/staff_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class ForceChangePasswordScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final String userRole;

  const ForceChangePasswordScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.userRole = 'CUSTOMER',
  });

  @override
  State<ForceChangePasswordScreen> createState() =>
      _ForceChangePasswordScreenState();
}

class _ForceChangePasswordScreenState extends State<ForceChangePasswordScreen> {
  final AuthViewModel _viewModel = AuthViewModel();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  Future<void> _changePassword() async {
    final success = await _viewModel.changePassword(
      widget.userId,
      _passwordController.text,
      _confirmController.text,
    );
    if (success) {
      if (!mounted) return;

      Widget destination;
      if (widget.userRole == 'ADMIN') {
        destination = const AdminDashboardScreen();
      } else if (widget.userRole == 'STAFF') {
        destination = const StaffDashboardScreen();
      } else {
        destination = const FamilyHomeScreen();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    // Do NOT dispose the singleton _viewModel
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Đổi mật khẩu bảo mật',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading:
            false, // Force them to change it, no back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.security, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Chào ${widget.userName},',
              style: AppTextStyles.heading1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Đây là lần đăng nhập đầu tiên của bạn. Vui lòng đổi mật khẩu mặc định để bảo vệ hồ sơ sức khỏe cá nhân.',
              style: AppTextStyles.subtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) {
                if (_viewModel.errorMsg != null) {
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.red.withValues(alpha: 0.1),
                        child: Text(
                          _viewModel.errorMsg!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu mới',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Xác nhận mật khẩu mới',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 32),

            ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) {
                return ElevatedButton(
                  onPressed: _viewModel.isLoading ? null : _changePassword,
                  child: _viewModel.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Cập nhật & Tiếp tục'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
