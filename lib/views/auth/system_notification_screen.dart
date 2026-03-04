import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SystemNotificationScreen extends StatefulWidget {
  final bool embedded;
  const SystemNotificationScreen({super.key, this.embedded = false});

  @override
  State<SystemNotificationScreen> createState() =>
      _SystemNotificationScreenState();
}

class _SystemNotificationScreenState extends State<SystemNotificationScreen> {
  int _selectedTab = 0; // 0: Tất cả, 1: Chưa đọc, 2: Quan trọng
  int _selectedIndex = 2; // Bottom nav index

  @override
  Widget build(BuildContext context) {
    final Widget mainContent = Column(
      children: [
        Container(
          color: Colors.white,
          child: Row(
            children: [
              _buildTabItem(title: 'Tất cả', index: 0),
              _buildTabItem(title: 'Chưa đọc', index: 1),
              _buildTabItem(title: 'Quan trọng', index: 2),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildNotificationItem(
                  icon: Icons.science_outlined,
                  iconColor: AppColors.primary,
                  iconBgColor: AppColors.primary.withValues(alpha: 0.1),
                  title: 'Kết quả xét nghiệm mới',
                  message:
                      'Kết quả xét nghiệm máu của bạn đã có. Vui lòng kiểm tra chi tiết trong mục hồ sơ y tế.',
                  time: '10 phút trước',
                  isUnread: true,
                  bgColor: AppColors.primary.withValues(alpha: 0.05),
                ),
                Container(
                  height: 1,
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
                _buildNotificationItem(
                  icon: Icons.sync_rounded,
                  iconColor: Colors.green[600]!,
                  iconBgColor: Colors.green[50]!,
                  title: 'Đồng bộ dữ liệu thành công',
                  message:
                      'Dữ liệu sức khỏe từ Apple Watch của bạn đã được cập nhật hoàn tất vào hệ thống.',
                  time: '1 giờ trước',
                ),
                Container(
                  height: 1,
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text(
            'Thông báo',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: mainContent,
      );
    }

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
          'Thông báo',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: mainContent,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_heart_outlined),
            activeIcon: Icon(Icons.monitor_heart),
            label: 'Sức khỏe',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            activeIcon: Icon(Icons.notifications),
            label: 'Thông báo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({required String title, required int index}) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String message,
    required String time,
    bool isUnread = false,
    Color bgColor = Colors.white,
  }) {
    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isUnread) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.cyan[400],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyan[400]!.withValues(alpha: 0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  time.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.close, color: AppColors.textLight, size: 20),
          ),
        ],
      ),
    );
  }
}
