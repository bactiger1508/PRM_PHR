import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'staff_management_screen.dart';
import 'system_audit_log_screen.dart';
import 'medical_code_config_screen.dart';
import 'tag_management_screen.dart';
import '../auth/personal_settings_screen.dart';
import '../login/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildOverviewPage(context),
          const StaffManagementScreen(embedded: true),
          const SystemAuditLogScreen(embedded: true),
          _buildSettingsPage(context),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        backgroundColor: Colors.white,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Nhân sự',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Nhật ký',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewPage(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Bảng điều khiển Quản trị',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () {},
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: AppColors.textPrimary),
                onPressed: () {},
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Text('AD', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GridView.count(
              crossAxisCount: 1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              childAspectRatio: 3.5,
              children: [
                _buildStatCard('Tổng hồ sơ', '12,450', '+5.2% tháng này', Icons.assignment_ind, Colors.blue),
                _buildStatCard('Đang hoạt động', '3,200', '+1.8% hôm nay', Icons.favorite, Colors.teal),
                _buildStatCard('Yêu cầu xử lý', '145', '-12 đơn mới', Icons.pending_actions, Colors.orange),
                _buildStatCard('Tỉ lệ lưu trữ', '98.4%', 'Ổn định', Icons.cloud_done, Colors.indigo),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tăng trưởng Hồ sơ mới', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  AspectRatio(
                    aspectRatio: 1.7,
                    child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(image: NetworkImage('https://quickchart.io/chart?c={type:%27line%27,data:{labels:[%27T2%27,%27T3%27,%27T4%27,%27T5%27,%27T6%27,%27T7%27,%27CN%27],datasets:[{label:%27Hồ%20sơ%27,data:[10,25,45,30,55,80,75],fill:true,borderColor:%27rgb(54,162,235)%27,backgroundColor:%27rgba(54,162,235,0.1)%27,tension:0.4}]}}')),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String trend, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(trend, style: TextStyle(color: trend.contains('+') ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Icon(icon, color: color.withValues(alpha: 0.8), size: 28),
        ],
      ),
    );
  }

  Widget _buildSettingsPage(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Cài đặt hệ thống', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: 'Thông tin cá nhân Admin',
            subtitle: 'Xem và sửa thông tin cá nhân',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalSettingsScreen(embedded: false)));
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            icon: Icons.label_outline,
            title: 'Quản lý nhãn Tag',
            subtitle: 'Cấu hình các loại nhãn tài liệu',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const TagManagementScreen()));
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            icon: Icons.qr_code_scanner,
            title: 'Cấu hình mã Y tế',
            subtitle: 'Định dạng mã BN tự động',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MedicalCodeConfigScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({required IconData icon, required String title, String? subtitle, Color? color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border, width: 0.5)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: (color ?? AppColors.primary).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color ?? AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color ?? AppColors.textPrimary)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
