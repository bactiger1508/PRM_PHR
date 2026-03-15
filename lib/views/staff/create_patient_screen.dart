import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/create_patient_viewmodel.dart';
import '../theme/app_theme.dart';

class CreatePatientScreen extends StatefulWidget {
  const CreatePatientScreen({super.key});

  @override
  State<CreatePatientScreen> createState() => _CreatePatientScreenState();
}

class _CreatePatientScreenState extends State<CreatePatientScreen> {
  final CreatePatientViewModel _viewModel = CreatePatientViewModel();

  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  static const Color successTeal = Color(0xFF00897B);

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tạo hồ sơ bệnh nhân mới',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Thông tin cá nhân',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            _buildInputLabel('Họ và tên *'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _nameController,
              hintText: 'Nguyễn Văn A',
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel('Ngày sinh *'),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _dobController,
                        hintText: 'dd/mm/yyyy',
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        suffixIcon: const Icon(Icons.calendar_today, size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel('Số điện thoại'),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _phoneController,
                        hintText: '09xx xxx xxx',
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildInputLabel('Email (Để tạo tài khoản đăng nhập)'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _emailController,
              hintText: 'bo-trong-neu-la-tre-em.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 8),
            const Text(
              '* Nếu không có Email, bệnh nhân sẽ không có tài khoản riêng nhưng vẫn có Mã Y Tế để người thân quản lý.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),

            ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) {
                return Column(
                  children: [
                    if (_viewModel.errorMsg != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_viewModel.errorMsg!, style: const TextStyle(color: Colors.red)),
                      ),
                      const SizedBox(height: 16),
                    ],

                    ElevatedButton.icon(
                      onPressed: _viewModel.isLoading
                          ? null
                          : () async {
                              await _viewModel.createPatient(
                                fullName: _nameController.text,
                                dob: _dobController.text,
                                phone: _phoneController.text,
                                email: _emailController.text,
                                createdByStaffId: 1,
                              );
                            },
                      icon: const Icon(Icons.save),
                      label: Text(_viewModel.isLoading ? 'Đang lưu...' : 'Lưu hồ sơ'),
                    ),

                    if (_viewModel.isSuccess) ...[
                      const SizedBox(height: 24),
                      _buildSuccessPreview(_viewModel.successMedicalCode, _emailController.text.isNotEmpty),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        hintText: hintText,
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildSuccessPreview(String medicalCode, bool hasAccount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: successTeal.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: successTeal.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: successTeal, size: 48),
          const SizedBox(height: 12),
          const Text('Tạo hồ sơ thành công', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: successTeal)),
          const SizedBox(height: 4),
          Text(
            hasAccount 
              ? 'Tài khoản đăng nhập: Email\nMật khẩu mặc định: 123456' 
              : 'Hồ sơ đã được lưu. Hãy dùng Mã Y Tế này để liên kết với tài khoản của cha/mẹ.',
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MÃ Y TẾ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                      Text(medicalCode, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: medicalCode));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã sao chép mã y tế')));
                  },
                  icon: const Icon(Icons.content_copy, size: 20, color: AppColors.primary),
                ),
              ],
            ),
          ),
          
          if (!hasAccount) ...[
            const SizedBox(height: 16),
            if (_viewModel.accessCode == null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _viewModel.isLoading ? null : () => _viewModel.generateAccessCode(),
                  icon: const Icon(Icons.link),
                  label: const Text('Tạo Mã liên kết (Family)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.withValues(alpha: 0.5))),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('MÃ LIÊN KẾT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                          Text(
                            _viewModel.accessCode!, 
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange, letterSpacing: 2)
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _viewModel.accessCode!));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã sao chép mã liên kết')));
                      },
                      icon: const Icon(Icons.content_copy, size: 20, color: Colors.orange),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
