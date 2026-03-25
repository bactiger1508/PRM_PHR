import 'package:flutter/material.dart';
import '../../domain/entities/system_notification_entity.dart';
import '../../data/implementations/system_notification_repository_impl.dart';
import 'auth_viewmodel.dart';

class SystemNotificationViewModel extends ChangeNotifier {
  final SystemNotificationRepositoryImpl _repo = SystemNotificationRepositoryImpl();
  
  List<SystemNotificationEntity> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;

  List<SystemNotificationEntity> get notifications => _notifications;
  List<SystemNotificationEntity> get unreadNotifications => 
      _notifications.where((n) => !n.isRead).toList();
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  Future<void> loadUserNotifications() async {
    final user = AuthViewModel.instance.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await _repo.getUserNotifications(user.id!);
      _unreadCount = await _repo.getUnreadCount(user.id!);
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int notificationId) async {
    final success = await _repo.markAsRead(notificationId);
    if (success) {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = SystemNotificationEntity(
          id: _notifications[index].id,
          userId: _notifications[index].userId,
          title: _notifications[index].title,
          message: _notifications[index].message,
          type: _notifications[index].type,
          isRead: true, // Marked as read
          createdAt: _notifications[index].createdAt,
        );
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        notifyListeners();
      }
    }
  }

  Future<void> markAllAsRead() async {
    final user = AuthViewModel.instance.currentUser;
    if (user == null) return;

    final success = await _repo.markAllAsRead(user.id!);
    if (success) {
      _notifications = _notifications.map((n) {
        if (n.isRead) return n;
        return SystemNotificationEntity(
          id: n.id,
          userId: n.userId,
          title: n.title,
          message: n.message,
          type: n.type,
          isRead: true,
          createdAt: n.createdAt,
        );
      }).toList();
      _unreadCount = 0;
      notifyListeners();
    }
  }

  /// Hàm tiện ích để hệ thống dùng gửi thông báo
  Future<void> sendNotification({
    required int userId,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      final notif = SystemNotificationEntity(
        userId: userId,
        title: title,
        message: message,
        type: type,
      );
      await _repo.insertNotification(notif);
      
      // Nếu user đang đăng nhập chính là user nhận thì reload list
      if (AuthViewModel.instance.currentUser?.id == userId) {
        await loadUserNotifications();
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }
}
