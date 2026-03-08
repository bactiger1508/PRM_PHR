import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../staff/staff_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../customer/family_home_screen.dart';

class ForceChangePasswordScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final String userRole;

  const ForceChangePasswordScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userRole,
  });

  @override
  State<ForceChangePasswordScreen> createState() => _ForceChangePasswordScreenState();
}

class _ForceChangePasswordScreenState extends State<ForceChangePasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  final _viewModel = AuthViewModel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.security_update_good, size: 64, color: AppColors.primary),
                const SizedBox(height: 24),
                const Text(
                  'Đổi mật khẩu lần đầu',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Chào ${widget.userName}, vì lý do bảo mật, vui lòng thay đổi mật khẩu mặc định để tiếp tục sử dụng hệ thống.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),

                ListenableBuilder(
                  listenable: _viewModel,
                  builder: (context, _) {
                    if (_viewModel.errorMsg != null) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                        child: Text(_viewModel.errorMsg!, style: const TextStyle(color: Colors.red)),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                TextField(
                  controller: _newPasswordController,
                  obscureText: _obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu mới',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu',
                    prefixIcon: const Icon(Icons.lock_reset),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: () async {
                    final success = await _viewModel.changePassword(
                      widget.userId,
                      _newPasswordController.text,
                      _confirmPasswordController.text,
                    );

                    if (success && mounted) {
                      Widget destination;
                      if (widget.userRole == 'CUSTOMER') {
                        destination = const CustomerFamilyHomeScreen();
                      } else if (widget.userRole == 'ADMIN') {
                        destination = const AdminDashboardScreen();
                      } else {
                        destination = const StaffDashboardScreen();
                      }

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => destination),
                      );
                    }
                  },
                  child: const Text('Đổi mật khẩu & Đăng nhập'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
