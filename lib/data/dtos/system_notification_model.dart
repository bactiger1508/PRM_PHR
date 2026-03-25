import '../../domain/entities/system_notification_entity.dart';

class SystemNotificationModel extends SystemNotificationEntity {
  SystemNotificationModel({
    super.id,
    required super.userId,
    required super.title,
    required super.message,
    required super.type,
    super.isRead = false,
    super.createdAt,
  });

  factory SystemNotificationModel.fromJson(Map<String, dynamic> json) {
    return SystemNotificationModel(
      id: json['id'] as int?,
      userId: json['user_id'] as int,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      isRead: (json['is_read'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory SystemNotificationModel.fromEntity(SystemNotificationEntity entity) {
    return SystemNotificationModel(
      id: entity.id,
      userId: entity.userId,
      title: entity.title,
      message: entity.message,
      type: entity.type,
      isRead: entity.isRead,
      createdAt: entity.createdAt,
    );
  }
}
