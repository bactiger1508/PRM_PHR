import '../../domain/entities/system_notification_entity.dart';

abstract class SystemNotificationRepository {
  Future<List<SystemNotificationEntity>> getUserNotifications(int userId);
  Future<int> getUnreadCount(int userId);
  Future<int> insertNotification(SystemNotificationEntity notification);
  Future<bool> markAsRead(int notificationId);
  Future<bool> markAllAsRead(int userId);
}
