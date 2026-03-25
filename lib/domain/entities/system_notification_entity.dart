import 'package:flutter/material.dart';

class SystemNotificationEntity {
  final int? id;
  final int userId;
  final String title;
  final String message;
  final String type; // Tương đương với: INFO, WARNING, SUCCESS, DOCUMENT, FAMILY
  final bool isRead;
  final DateTime createdAt;

  SystemNotificationEntity({
    this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Giúp mapping tự động ra Icon hiển thị dựa trên type
  IconData get iconData {
    switch (type) {
      case 'DOCUMENT':
        return Icons.description_outlined;
      case 'FAMILY':
        return Icons.family_restroom;
      case 'WARNING':
      case 'SECURITY':
        return Icons.security_outlined;
      case 'SUCCESS':
        return Icons.check_circle_outline;
      case 'INFO':
      default:
        return Icons.info_outline;
    }
  }

  /// Giúp mapping màu sắc của icon
  Color get iconColor {
    switch (type) {
      case 'DOCUMENT':
        return Colors.blue;
      case 'FAMILY':
        return Colors.purple;
      case 'WARNING':
      case 'SECURITY':
        return Colors.red;
      case 'SUCCESS':
        return Colors.green;
      case 'INFO':
      default:
        return Colors.grey;
    }
  }
}
