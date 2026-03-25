import '../../domain/entities/tag_entity.dart';
import '../interfaces/tag_repository.dart';
import '../db/database_helper.dart';

class TagRepositoryImpl implements TagRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<TagEntity>> getAllTags() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT t.id, t.tag_name, t.created_at,
             COUNT(dt.document_id) AS doc_count
      FROM tags t
      LEFT JOIN document_tags dt ON dt.tag_id = t.id
      GROUP BY t.id
      ORDER BY t.tag_name ASC
    ''');

    return rows.map((r) => TagEntity(
      id: r['id'] as int,
      tagName: r['tag_name'] as String,
      documentCount: r['doc_count'] as int? ?? 0,
      createdAt: r['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int)
          : null,
    )).toList();
  }

  @override
  Future<TagEntity> createTag(String tagName) async {
    final db = await _dbHelper.database;
    final normalized = tagName.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw ArgumentError('Tên tag không hợp lệ');
    }
    final dup = await db.rawQuery(
      'SELECT id FROM tags WHERE LOWER(tag_name) = ?',
      [normalized],
    );
    if (dup.isNotEmpty) {
      final existingId = dup.first['id'] as int;
      final row = await db.query('tags', where: 'id = ?', whereArgs: [existingId]);
      final r = row.first;
      return TagEntity(
        id: existingId,
        tagName: r['tag_name'] as String,
        createdAt: r['created_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int)
            : null,
      );
    }
    final id = await db.insert('tags', {
      'tag_name': normalized,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    return TagEntity(
      id: id,
      tagName: normalized,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<bool> updateTag(int id, String newName) async {
    final db = await _dbHelper.database;
    final normalized = newName.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    final count = await db.update(
      'tags',
      {'tag_name': normalized},
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  @override
  Future<bool> deleteTag(int id) async {
    final db = await _dbHelper.database;
    final count = await db.delete('tags', where: 'id = ?', whereArgs: [id]);
    return count > 0;
  }
}
