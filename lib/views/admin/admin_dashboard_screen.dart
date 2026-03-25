import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'staff_management_screen.dart';
import 'system_audit_log_screen.dart';
import 'medical_code_config_screen.dart';
import 'tag_management_screen.dart';
import 'category_management_screen.dart';
import '../auth/personal_settings_screen.dart';
import '../../data/db/database_helper.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  // Dashboard data
  int _totalProfiles = 0;
  int _activeUsers = 0;
  List<_ChartPoint> _profileGrowth = [];
  List<_ChartPoint> _documentGrowth = [];
  bool _dashboardLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _dashboardLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;

      // Tổng số hồ sơ
      final profileCount = await db.rawQuery('SELECT COUNT(*) as cnt FROM patient_profiles');
      _totalProfiles = (profileCount.first['cnt'] as int?) ?? 0;

      // Số người hoạt động (ACTIVE users)
      final activeCount = await db.rawQuery("SELECT COUNT(*) as cnt FROM user_accounts WHERE status = 'ACTIVE'");
      _activeUsers = (activeCount.first['cnt'] as int?) ?? 0;

      // Tăng trưởng hồ sơ 7 ngày gần nhất
      _profileGrowth = await _getLast7DaysGrowth(db, 'patient_profiles');

      // Tăng trưởng tài liệu 7 ngày gần nhất
      _documentGrowth = await _getLast7DaysGrowth(db, 'medical_documents');
    } catch (_) {}
    if (mounted) setState(() => _dashboardLoading = false);
  }

  Future<List<_ChartPoint>> _getLast7DaysGrowth(dynamic db, String table) async {
    final now = DateTime.now();
    final labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    List<_ChartPoint> points = [];

    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final startMs = day.millisecondsSinceEpoch;
      final endMs = day.add(const Duration(days: 1)).millisecondsSinceEpoch;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM $table WHERE created_at >= ? AND created_at < ?',
        [startMs, endMs],
      );
      final count = (result.first['cnt'] as int?) ?? 0;
      // weekday: 1=Mon .. 7=Sun
      final label = labels[day.weekday - 1];
      points.add(_ChartPoint(label, count));
    }
    return points;
  }

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
            label: 'Người dùng',
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
      ),
      body: _dashboardLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Stat cards
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('Tổng hồ sơ', '$_totalProfiles', Icons.assignment_ind, Colors.blue)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('Đang hoạt động', '$_activeUsers', Icons.people, Colors.teal)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Biểu đồ tăng trưởng hồ sơ
                    _buildChartCard('Tăng trưởng Hồ sơ (7 ngày)', _profileGrowth, Colors.blue),
                    const SizedBox(height: 16),
                    // Biểu đồ tăng trưởng tài liệu
                    _buildChartCard('Tăng trưởng Tài liệu (7 ngày)', _documentGrowth, Colors.teal),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, List<_ChartPoint> data, Color color) {
    final maxVal = data.fold<int>(0, (prev, e) => e.value > prev ? e.value : prev);
    final chartMax = maxVal == 0 ? 1 : maxVal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((point) {
                final ratio = point.value / chartMax;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${point.value}', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: (120 * ratio).clamp(4.0, 120.0),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(point.label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
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
            icon: Icons.category_outlined,
            title: 'Quản lý danh mục tài liệu',
            subtitle: 'Xét nghiệm, Đơn thuốc, Chẩn đoán,...',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoryManagementScreen()));
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

class _ChartPoint {
  final String label;
  final int value;
  _ChartPoint(this.label, this.value);
}
