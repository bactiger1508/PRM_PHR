class AuditLogEntity {
  final int? id;
  final int? userId;
  final String? userName;
  final String? userRole;
  final String action;
  final String? entityType;
  final int? entityId;
  final String? details;
  final DateTime? timestamp;

  AuditLogEntity({
    this.id,
    this.userId,
    this.userName,
    this.userRole,
    required this.action,
    this.entityType,
    this.entityId,
    this.details,
    this.timestamp,
  });
}
