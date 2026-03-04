import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  int _selectedTab = 0;
  int _selectedIndex = 1; // "Người dùng" selected

  static const Color statusActive = Color(0xFF00897B);
  static const Color statusLocked = Color(0xFFD32F2F);

  // Mock data for the UI
  final List<Map<String, dynamic>> _users = [
    {
      'name': 'BS. Nguyễn Văn An',
      'role': 'Bác sĩ chuyên khoa',
      'status': 'Hoạt động',
      'isActive': true,
      'avatarUrl':
          'https://ui-avatars.com/api/?name=Nguyen+Van+An&background=e0e7ff&color=156bc1',
    },
    {
      'name': 'BS. Trần Thị Mai',
      'role': 'Điều dưỡng trưởng',
      'status': 'Hoạt động',
      'isActive': true,
      'avatarUrl':
          'https://ui-avatars.com/api/?name=Tran+Thi+Mai&background=fce7f3&color=db2777',
    },
    {
      'name': 'Lê Minh Hoàng',
      'role': 'Khách hàng VIP',
      'status': 'Đã khóa',
      'isActive': false,
      'avatarUrl':
          'https://ui-avatars.com/api/?name=Le+Minh+Hoang&background=e2e8f0&color=475569',
    },
    {
      'name': 'Phạm Thanh Thủy',
      'role': 'Khách hàng',
      'status': 'Hoạt động',
      'isActive': true,
      'avatarUrl':
          'https://ui-avatars.com/api/?name=Pham+Thanh+Thuy&background=dcfce7&color=166534',
    },
    {
      'name': 'BS. Vũ Anh Tuấn',
      'role': 'Khoa nội',
      'status': 'Hoạt động',
      'isActive': true,
      'avatarUrl':
          'https://ui-avatars.com/api/?name=Vu+Anh+Tuan&background=ffedd5&color=c2410c',
    },
  ];

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
          'Quản lý người dùng',
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112), // Search bar + Tabs
          child: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm theo tên, email...',
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
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                // Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildTabBtn('Tất cả', 0),
                      _buildTabBtn('Nhân viên y tế', 1),
                      _buildTabBtn('Khách hàng', 2),
                    ],
                  ),
                ),
                Container(color: AppColors.border, height: 1), // Divider
              ],
            ),
          ),
        ),
      ),
      body: ListView.separated(
        itemCount: _users.length,
        separatorBuilder: (context, index) => Container(
          height: 1,
          color: AppColors.border.withValues(alpha: 0.5),
        ),
        itemBuilder: (context, index) {
          final user = _users[index];
          return _buildUserItem(user);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person_add, color: Colors.white),
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
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: 'Người dùng',
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

  Widget _buildTabBtn(String title, int index) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildUserItem(Map<String, dynamic> user) {
    bool isActive = user['isActive'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                  image: DecorationImage(
                    image: NetworkImage(user['avatarUrl']),
                    fit: BoxFit.cover,
                    colorFilter: isActive
                        ? null
                        : const ColorFilter.mode(
                            Colors.grey,
                            BlendMode.saturation,
                          ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isActive ? statusActive : statusLocked,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? AppColors.textPrimary
                        : AppColors.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      TextSpan(text: '${user['role']} • '),
                      TextSpan(
                        text: user['status'],
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isActive ? statusActive : statusLocked,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}
