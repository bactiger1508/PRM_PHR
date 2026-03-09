import '../../domain/entities/category_entity.dart';
import '../interfaces/category_repository.dart';
import '../db/database_helper.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<CategoryEntity>> getAllCategories() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT dc.id, dc.name, dc.description,
             COUNT(md.id) AS doc_count
      FROM document_categories dc
      LEFT JOIN medical_documents md ON md.category_id = dc.id AND md.is_deleted = 0
      GROUP BY dc.id
      ORDER BY dc.name ASC
    ''');

    return rows.map((r) => CategoryEntity(
      id: r['id'] as int,
      name: r['name'] as String,
      description: r['description'] as String?,
      documentCount: r['doc_count'] as int? ?? 0,
    )).toList();
  }

  @override
  Future<CategoryEntity> createCategory(String name, String? description) async {
    final db = await _dbHelper.database;
    final id = await db.insert('document_categories', {
      'name': name.trim(),
      'description': description?.trim(),
    });
    return CategoryEntity(
      id: id,
      name: name.trim(),
      description: description?.trim(),
    );
  }

  @override
  Future<bool> updateCategory(int id, {String? name, String? description}) async {
    final db = await _dbHelper.database;
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name.trim();
    if (description != null) updates['description'] = description.trim();
    if (updates.isEmpty) return false;

    final count = await db.update(
      'document_categories',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  @override
  Future<bool> deleteCategory(int id) async {
    final db = await _dbHelper.database;
    final count = await db.delete(
      'document_categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }
}
