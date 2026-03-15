import '../../domain/entities/audit_log_entity.dart';
import '../db/database_helper.dart';

class AuditLogRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<AuditLogEntity>> getLogs({
    DateTime? from,
    DateTime? to,
    String? role,
  }) async {
    final db = await _dbHelper.database;

    final where = <String>[];
    final args = <dynamic>[];

    if (from != null) {
      where.add('al.timestamp >= ?');
      args.add(from.millisecondsSinceEpoch);
    }
    if (to != null) {
      where.add('al.timestamp < ?');
      args.add(to.millisecondsSinceEpoch);
    }
    if (role != null && role.isNotEmpty) {
      where.add('ua.role = ?');
      args.add(role);
    }

    final whereClause = where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';

    final rows = await db.rawQuery('''
      SELECT al.*, ua.full_name AS user_name, ua.role AS user_role
      FROM audit_logs al
      LEFT JOIN user_accounts ua ON ua.id = al.user_id
      $whereClause
      ORDER BY al.timestamp DESC
    ''', args);

    return rows.map((r) => AuditLogEntity(
      id: r['id'] as int?,
      userId: r['user_id'] as int?,
      userName: r['user_name'] as String?,
      userRole: r['user_role'] as String?,
      action: r['action'] as String? ?? '',
      entityType: r['entity_type'] as String?,
      entityId: r['entity_id'] as int?,
      details: r['details'] as String?,
      timestamp: r['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(r['timestamp'] as int)
          : null,
    )).toList();
  }
}
