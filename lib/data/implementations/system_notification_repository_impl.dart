import '../../domain/entities/system_notification_entity.dart';
import '../interfaces/system_notification_repository.dart';
import '../db/database_helper.dart';
import '../dtos/system_notification_model.dart';

class SystemNotificationRepositoryImpl implements SystemNotificationRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<SystemNotificationEntity>> getUserNotifications(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'system_notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC', // Mới nhất lên trên
    );

    return maps.map((json) => SystemNotificationModel.fromJson(json)).toList();
  }

  @override
  Future<int> getUnreadCount(int userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM system_notifications WHERE user_id = ? AND is_read = 0',
      [userId],
    );
    return result.first.values.first as int;
  }

  @override
  Future<int> insertNotification(SystemNotificationEntity notification) async {
    final db = await _dbHelper.database;
    final model = SystemNotificationModel.fromEntity(notification);
    return await db.insert('system_notifications', model.toJson());
  }

  @override
  Future<bool> markAsRead(int notificationId) async {
    final db = await _dbHelper.database;
    final count = await db.update(
      'system_notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
    return count > 0;
  }

  @override
  Future<bool> markAllAsRead(int userId) async {
    final db = await _dbHelper.database;
    final count = await db.update(
      'system_notifications',
      {'is_read': 1},
      where: 'user_id = ? AND is_read = 0',
      whereArgs: [userId],
    );
    return count > 0;
  }
}
