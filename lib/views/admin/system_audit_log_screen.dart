import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SystemAuditLogScreen extends StatefulWidget {
  final bool embedded;
  const SystemAuditLogScreen({super.key, this.embedded = false});

  @override
  State<SystemAuditLogScreen> createState() => _SystemAuditLogScreenState();
}

class _SystemAuditLogScreenState extends State<SystemAuditLogScreen> {
  int _selectedIndex = 2; // "Nhật ký"

  @override
  Widget build(BuildContext context) {
    final Widget mainContent = Column(
      children: [
        // Search
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm nhân viên hoặc hành động...',
              hintStyle: const TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textLight,
              ),
              filled: true,
              fillColor: AppColors.backgroundLight,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        // Filters
        Container(
          color: Colors.white,
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip('Thời gian'),
              const SizedBox(width: 8),
              _buildFilterChip('Người dùng'),
              const SizedBox(width: 8),
              _buildFilterChip('Hành động'),
            ],
          ),
        ),
        Container(color: AppColors.border, height: 1), // Divider
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _buildDateHeader('HÔM NAY'),
              _buildLogItem(
                name: 'BS. Nguyễn Minh Anh',
                time: '09:45',
                action: 'Đã sửa hồ sơ bệnh nhân #BN0921',
                actionColor: AppColors.primary,
                device: 'MacBook Pro • 192.168.1.15',
                deviceIcon: Icons.laptop_mac,
                avatarUrl:
                    'https://ui-avatars.com/api/?name=Nguyen+Minh+Anh&background=e0e7ff&color=156bc1',
              ),
              const Divider(height: 1, color: AppColors.border),
              _buildLogItem(
                name: 'Lê Hoàng Nam (IT)',
                time: '08:12',
                action: 'Đăng nhập hệ thống quản trị',
                actionColor: AppColors.textPrimary,
                device: 'Windows PC • Office Network',
                deviceIcon: Icons.desktop_windows,
                avatarUrl:
                    'https://ui-avatars.com/api/?name=Le+Hoang+Nam&background=e2e8f0&color=475569',
              ),
              _buildDateHeader('HÔM QUA'),
              _buildLogItem(
                name: 'ĐD. Trần Thu Thủy',
                time: '17:30',
                action: 'Xuất báo cáo doanh thu tháng 10',
                actionColor: AppColors.textPrimary,
                device: 'iPad Air • Safari Browser',
                deviceIcon: Icons.tablet_mac,
                avatarUrl:
                    'https://ui-avatars.com/api/?name=Tran+Thu+Thuy&background=fce7f3&color=db2777',
              ),
              const Divider(height: 1, color: AppColors.border),
              _buildLogItem(
                name: 'BS. Phạm Gia Bảo',
                time: '15:20',
                action: 'Xóa hồ sơ bệnh nhân #BN4421',
                actionColor: Colors.red[500]!,
                device: 'iPhone 15 Pro • App v2.4',
                deviceIcon: Icons.smartphone,
                avatarUrl:
                    'https://ui-avatars.com/api/?name=Pham+Gia+Bao&background=ffedd5&color=c2410c',
              ),
            ],
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
          centerTitle: true,
          title: const Text(
            'Nhật ký hệ thống',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
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
          'Nhật ký hệ thống',
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
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: 'Bệnh nhân',
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

  Widget _buildFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(String date) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        date,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildLogItem({
    required String name,
    required String time,
    required String action,
    required Color actionColor,
    required String device,
    required IconData deviceIcon,
    required String avatarUrl,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(avatarUrl),
            backgroundColor: AppColors.border,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  action,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: actionColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(deviceIcon, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      device,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
