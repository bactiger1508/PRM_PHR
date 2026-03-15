import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/family_member_viewmodel.dart';

class AddFamilyMemberScreen extends StatefulWidget {
  const AddFamilyMemberScreen({super.key});

  @override
  State<AddFamilyMemberScreen> createState() => _AddFamilyMemberScreenState();
}

class _AddFamilyMemberScreenState extends State<AddFamilyMemberScreen> {
  final _medicalCodeController = TextEditingController();
  final _accessCodeController = TextEditingController();
  final FamilyMemberViewModel _viewModel = FamilyMemberViewModel();
  String _selectedRelationship = 'Con';

  final List<String> _relationships = ['Con', 'Vợ/Chồng', 'Bố/Mẹ', 'Anh/Chị/Em', 'Khác'];

  @override
  void dispose() {
    _medicalCodeController.dispose();
    _accessCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Thêm thành viên gia đình',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.group_add_outlined, size: 64, color: AppColors.primary),
            const SizedBox(height: 24),
            const Text(
              'Liên kết hồ sơ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Nhập thông tin hồ sơ của người thân để thực hiện liên kết và quản lý.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            _buildLabel('Mã Y Tế của người thân *'),
            const SizedBox(height: 8),
            TextField(
              controller: _medicalCodeController,
              decoration: const InputDecoration(
                hintText: 'VD: PHR-16022004-24052024-01',
                prefixIcon: Icon(Icons.qr_code),
              ),
            ),
            const SizedBox(height: 20),

            _buildLabel('Mã truy cập (Access Code) *'),
            const SizedBox(height: 8),
            TextField(
              controller: _accessCodeController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Nhập mã bảo mật để liên kết',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 20),

            _buildLabel('Mối quan hệ *'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedRelationship,
                  isExpanded: true,
                  items: _relationships.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() => _selectedRelationship = newValue);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 40),

            ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) => ElevatedButton(
                onPressed: _viewModel.isLoading
                    ? null
                    : () async {
                        final user = AuthViewModel.instance.currentUser;
                        if (user == null || user.id == null) return;

                        final success = await _viewModel.linkMember(
                          customerId: user.id!,
                          medicalCode: _medicalCodeController.text.trim(),
                          accessCode: _accessCodeController.text.trim(),
                          relationship: _selectedRelationship,
                        );

                        if (success) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Liên kết thành công!')),
                            );
                            Navigator.pop(context, true);
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_viewModel.error ?? 'Lỗi liên kết')),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: Text(_viewModel.isLoading ? 'Đang xác thực...' : 'Thực hiện liên kết'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
    );
  }
}
