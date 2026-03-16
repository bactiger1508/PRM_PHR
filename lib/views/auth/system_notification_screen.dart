import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../../viewmodels/system_notification_viewmodel.dart';

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
  
  final SystemNotificationViewModel _viewModel = SystemNotificationViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.loadUserNotifications();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) {
      if (diff.inDays < 7) return '${diff.inDays} ngày trước';
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } else if (diff.inHours > 0) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  @override
  Widget build(BuildContext context) {
    final allNotifs = _viewModel.notifications;
    final unreadNotifs = _viewModel.unreadNotifications;
    final importantNotifs = allNotifs.where((n) => n.type == 'SECURITY' || n.type == 'WARNING').toList();

    var displayList = allNotifs;
    if (_selectedTab == 1) displayList = unreadNotifs;
    if (_selectedTab == 2) displayList = importantNotifs;

    final Widget mainContent = Column(
      children: [
        Container(
          color: Colors.white,
          child: Row(
            children: [
              _buildTabItem(title: 'Tất cả', index: 0, count: allNotifs.length),
              _buildTabItem(title: 'Chưa đọc', index: 1, count: unreadNotifs.length),
              _buildTabItem(title: 'Quan trọng', index: 2, count: importantNotifs.length),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        if (_viewModel.isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (displayList.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Không có thông báo nào', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              itemCount: displayList.length,
              separatorBuilder: (context, index) => Container(
                height: 1,
                color: AppColors.border.withValues(alpha: 0.5),
              ),
              itemBuilder: (context, index) {
                final notif = displayList[index];
                return GestureDetector(
                  onTap: () {
                    if (!notif.isRead && notif.id != null) {
                      _viewModel.markAsRead(notif.id!);
                    }
                  },
                  child: _buildNotificationItem(
                    icon: notif.iconData,
                    iconColor: notif.iconColor,
                    iconBgColor: notif.iconColor.withValues(alpha: 0.1),
                    title: notif.title,
                    message: notif.message,
                    time: _formatTimeAgo(notif.createdAt),
                    isUnread: !notif.isRead,
                    bgColor: notif.isRead ? Colors.white : AppColors.primary.withValues(alpha: 0.05),
                  ),
                );
              },
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
          actions: [
            if (_viewModel.unreadCount > 0)
              TextButton(
                onPressed: () => _viewModel.markAllAsRead(),
                child: const Text('Đọc tất cả'),
              )
          ],
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
          if (_viewModel.unreadCount > 0)
            TextButton(
              onPressed: () => _viewModel.markAllAsRead(),
              child: const Text('Đọc tất cả'),
            ),
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

  Widget _buildTabItem({required String title, required int index, required int count}) {
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              if (count > 0 && index == 1) // Chỉ hiện số cho tab "Chưa đọc" nếu thích
                Container(
                  padding: const EdgeInsets.all(4),
                  margin: const EdgeInsets.only(left: 4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    count > 9 ? '9+' : count.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
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
        ],
      ),
    );
  }
}

