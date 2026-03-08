import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../login/login_screen.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../data/implementations/patient_repository_impl.dart';
import '../../domain/entities/patient_entity.dart';
import '../../data/dtos/patient_model.dart';
import 'forgot_password_screen.dart';

class PersonalSettingsScreen extends StatefulWidget {
  final bool embedded;
  const PersonalSettingsScreen({super.key, this.embedded = false});

  @override
  State<PersonalSettingsScreen> createState() => _PersonalSettingsScreenState();
}

class _PersonalSettingsScreenState extends State<PersonalSettingsScreen> {
  PatientEntity? _patientProfile;


  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final currentUser = AuthViewModel.instance.currentUser;
    if (currentUser != null && currentUser.role == 'CUSTOMER') {
      final repo = PatientRepositoryImpl();
      final profile = await repo.getPatientByPhoneOrEmail(
        phone: currentUser.phone, 
        email: currentUser.email
      );
      if (mounted) {
        setState(() {
          _patientProfile = profile;
        });
      }
    } else {
      if (mounted) {
        setState(() {});
      }
    }
  }

  String _calculateAge(String? dob) {
    if (dob == null || dob.isEmpty) return 'Không có';
    try {
      DateTime birthDate = DateFormat('dd/MM/yyyy').parse(dob);
      DateTime today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age.toString();
    } catch (e) {
      return 'Không có';
    }
  }

  Future<void> _showUpdateDialog() async {
    final currentUser = AuthViewModel.instance.currentUser;
    if (currentUser == null || currentUser.role != 'CUSTOMER' || _patientProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chức năng này dành cho bệnh nhân có hồ sơ.')),
      );
      return;
    }

    final phoneController = TextEditingController(text: _patientProfile!.phone);
    final dobController = TextEditingController(text: _patientProfile!.dob);

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cập nhật thông tin', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dobController,
                decoration: const InputDecoration(
                  labelText: 'Ngày sinh (dd/mm/yyyy)',
                  prefixIcon: Icon(Icons.cake_outlined),
                ),
                readOnly: true,
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    dobController.text = DateFormat('dd/MM/yyyy').format(picked);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                final repo = PatientRepositoryImpl();
                final success = await repo.updatePatientProfile(
                  _patientProfile!.id!,
                  dob: dobController.text,
                  phone: phoneController.text,
                );
                if (success) {
                  if (mounted) Navigator.pop(context);
                  _loadProfile();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Lưu', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAccessCodeDialog() async {
    if (_patientProfile == null) return;
    
    // If we already have a code, show it
    if (_patientProfile!.accessCode != null && _patientProfile!.accessCode!.isNotEmpty) {
      _displayAccessCode(_patientProfile!.accessCode!);
      return;
    }

    // Otherwise, generate it
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final repo = PatientRepositoryImpl();
      final newCode = await repo.generateAccessCode(_patientProfile!.medicalCode);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      
      setState(() {
        _patientProfile = PatientModel(
          id: _patientProfile!.id,
          medicalCode: _patientProfile!.medicalCode,
          accessCode: newCode,
          fullName: _patientProfile!.fullName,
          dob: _patientProfile!.dob,
          phone: _patientProfile!.phone,
          email: _patientProfile!.email,
          status: _patientProfile!.status,
          createdBy: _patientProfile!.createdBy,
          createdAt: _patientProfile!.createdAt,
          updatedAt: DateTime.now(),
        );
      });
      _displayAccessCode(newCode);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải mã: $e')),
      );
    }
  }

  void _displayAccessCode(String code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mã liên kết Family', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sử dụng mã dưới đây để người thân (Cha/Mẹ) có thể liên kết và quản lý hồ sơ của bạn:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép mã liên kết!'), duration: Duration(seconds: 1)),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      code,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.orange, letterSpacing: 8),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.copy, color: Colors.orange, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text('Đóng', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthViewModel.instance.currentUser;
    final String name = _patientProfile?.fullName ?? user?.fullName ?? 'Không có';
    final String age = _calculateAge(_patientProfile?.dob);
    final String dob = _patientProfile?.dob ?? 'Không có';
    final String medicalCode = _patientProfile?.medicalCode ?? 'N/A';
    final String phone = (_patientProfile?.phone != null && _patientProfile!.phone!.isNotEmpty) 
        ? _patientProfile!.phone! 
        : (user?.phone ?? 'Không có');
    final String email = user?.email ?? 'Không có';

    final Widget mainContent = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile Header with Avatar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      height: 112, width: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 4),
                        image: DecorationImage(
                          image: NetworkImage('https://ui-avatars.com/api/?name=${name.replaceAll(' ', '+')}&background=e0e7ff&color=156bc1&size=200'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _showUpdateDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(180, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Cập nhật hồ sơ', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Detailed Info Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: const Text('CHI TIẾT CÁ NHÂN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1)),
          ),
          Container(
            color: Colors.white,
            child: Column(
              children: [
                _buildInfoItem(
                  Icons.qr_code, 
                  'Mã y tế', 
                  medicalCode, 
                  onCopy: medicalCode != 'N/A' ? () {
                    Clipboard.setData(ClipboardData(text: medicalCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã sao chép mã y tế!'), duration: Duration(seconds: 1)),
                    );
                  } : null,
                ),
                _buildInfoItem(Icons.person_outline, 'Họ và tên', name),
                _buildInfoItem(Icons.cake_outlined, 'Ngày sinh', dob),
                _buildInfoItem(Icons.history, 'Tuổi', age),
                _buildInfoItem(Icons.phone_outlined, 'Số điện thoại', phone),
                _buildInfoItem(Icons.email_outlined, 'Gmail', email),
              ],
            ),
          ),

          // Settings Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: const Text('CÀI ĐẶT & BẢO MẬT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1)),
          ),
          Container(
            color: Colors.white,
            child: Column(
              children: [
                if (user?.role == 'CUSTOMER') ...[
                  _buildSettingsItem(
                    icon: Icons.link,
                    title: 'Mã liên kết',
                    showArrow: true,
                    titleColor: Colors.orange,
                    onTap: () {
                      _showAccessCodeDialog();
                    },
                  ),
                  const Divider(height: 1, indent: 64),
                ],
                _buildSettingsItem(
                  icon: Icons.lock_outline,
                  title: 'Đổi mật khẩu',
                  showArrow: true,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()));
                  },
                ),
                const Divider(height: 1, indent: 64),
                _buildSettingsItem(
                  icon: Icons.logout,
                  title: 'Đăng xuất',
                  titleColor: Colors.red,
                  showArrow: true,
                  onTap: () {
                    _showLogoutDialog(context);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: !widget.embedded,
        title: Text(widget.embedded ? 'Cá nhân' : 'Hồ sơ của tôi', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: mainContent,
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, {VoidCallback? onCopy}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textLight),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy, size: 18, color: AppColors.primary),
              onPressed: onCopy,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({required IconData icon, required String title, Color? titleColor, bool showArrow = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: (titleColor ?? AppColors.primary).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: titleColor ?? AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: titleColor ?? AppColors.textPrimary))),
            if (showArrow) const Icon(Icons.chevron_right, color: AppColors.textLight, size: 20),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn muốn đăng xuất khỏi hệ thống?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              AuthViewModel.instance.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
