import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Import All Screens
import '../login/login_screen.dart';
import '../auth/otp_verification_screen.dart';
import '../auth/personal_settings_screen.dart';
import '../auth/system_notification_screen.dart';
import '../auth/user_guide_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../admin/user_management_screen.dart';
import '../admin/system_audit_log_screen.dart';
import '../admin/medical_code_config_screen.dart';
import '../admin/tag_management_screen.dart';
import '../staff/staff_dashboard_screen.dart';
import '../staff/patient_list_screen.dart';
import '../staff/create_patient_screen.dart';
import '../staff/patient_detail_screen.dart';
import '../staff/family_home_screen.dart';
import '../documents/document_list_screen.dart';
import '../documents/add_document_screen.dart';
import '../documents/document_detail_screen.dart';
import '../documents/delete_document_screen.dart';
import '../documents/trash_screen.dart';

class DevMenuScreen extends StatelessWidget {
  const DevMenuScreen({super.key});

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Dev Testing Menu',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildSectionHeader('1. Chung & Xác thực (Auth)'),
          _buildItem(context, 'Login Screen', const LoginScreen()),
          _buildItem(
            context,
            'OTP Verification',
            const OtpVerificationScreen(),
          ),
          _buildItem(
            context,
            'Personal Settings',
            const PersonalSettingsScreen(),
          ),
          _buildItem(
            context,
            'System Notification',
            const SystemNotificationScreen(),
          ),
          _buildItem(context, 'User Guide', const UserGuideScreen()),

          _buildSectionHeader('2. Quản Trị Hệ Thống (Admin)'),
          _buildItem(context, 'Admin Dashboard', const AdminDashboardScreen()),
          _buildItem(context, 'User Management', const UserManagementScreen()),
          _buildItem(context, 'System Audit Log', const SystemAuditLogScreen()),
          _buildItem(
            context,
            'Medical Code Config',
            const MedicalCodeConfigScreen(),
          ),
          _buildItem(context, 'Tag Management', const TagManagementScreen()),

          _buildSectionHeader('3. NV Y Tế & Bệnh Nhân (Staff)'),
          _buildItem(context, 'Staff Dashboard', const StaffDashboardScreen()),
          _buildItem(context, 'Patient List', const PatientListScreen()),
          _buildItem(context, 'Create Patient', const CreatePatientScreen()),
          _buildItem(context, 'Patient Detail', const PatientDetailScreen()),
          _buildItem(context, 'Family Home', const FamilyHomeScreen()),

          _buildSectionHeader('4. Quản Lý Tài Liệu (Documents)'),
          _buildItem(context, 'Document List', const DocumentListScreen()),
          _buildItem(context, 'Add Document', const AddDocumentScreen()),
          _buildItem(context, 'Document Detail', const DocumentDetailScreen()),
          _buildItem(
            context,
            'Delete Document (Confirm)',
            const DeleteDocumentScreen(),
          ),
          _buildItem(context, 'Trash (Thùng rác)', const TrashScreen()),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, String title, Widget screen) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textLight,
        ),
        onTap: () => _navigateTo(context, screen),
      ),
    );
  }
}
