import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../domain/entities/medical_document_entity.dart';
import '../interfaces/medical_document_repository.dart';
import '../db/database_helper.dart';
import '../dtos/medical_document_model.dart';

class MedicalDocumentRepositoryImpl implements MedicalDocumentRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<int> createDocument(MedicalDocumentEntity doc) async {
    final db = await _dbHelper.database;

    MedicalDocumentModel model = MedicalDocumentModel(
      patientProfileId: doc.patientProfileId,
      categoryId: doc.categoryId,
      recordDate: doc.recordDate,
      title: doc.title,
      notes: doc.notes,
      status: doc.status,
      isDeleted: 0,
      createdBy: doc.createdBy,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final id = await db.insert('medical_documents', model.toJson());
    return id;
  }

  @override
  Future<void> addFileToDocument(
      int documentId, DocumentFileEntity file) async {
    final db = await _dbHelper.database;

    // Copy file vào thư mục app
    final appDir = await getApplicationDocumentsDirectory();
    final docDir = Directory(p.join(appDir.path, 'medical_docs', '$documentId'));
    if (!await docDir.exists()) {
      await docDir.create(recursive: true);
    }

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.filePath)}';
    final savedFile = File(p.join(docDir.path, fileName));
    await File(file.filePath).copy(savedFile.path);

    await db.insert('document_files', {
      'document_id': documentId,
      'file_path': savedFile.path,
      'file_type': file.fileType,
      'file_size': file.fileSize,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<void> addTagToDocument(int documentId, String tagName) async {
    final db = await _dbHelper.database;

    // Tìm hoặc tạo tag
    final existingTags = await db.query(
      'tags',
      where: 'tag_name = ?',
      whereArgs: [tagName],
    );

    int tagId;
    if (existingTags.isNotEmpty) {
      tagId = existingTags.first['id'] as int;
    } else {
      tagId = await db.insert('tags', {
        'tag_name': tagName,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    }

    // Thêm liên kết document-tag (ignore nếu đã tồn tại)
    try {
      await db.insert('document_tags', {
        'document_id': documentId,
        'tag_id': tagId,
      });
    } catch (_) {
      // Đã tồn tại, bỏ qua
    }
  }

  @override
  Future<List<MedicalDocumentEntity>> getDocumentsByPatient(
      int patientProfileId) async {
    final db = await _dbHelper.database;

    final docs = await db.rawQuery('''
      SELECT md.*, dc.name as category_name, ua.full_name as created_by_name
      FROM medical_documents md
      LEFT JOIN document_categories dc ON md.category_id = dc.id
      LEFT JOIN user_accounts ua ON md.created_by = ua.id
      WHERE md.patient_profile_id = ? AND md.is_deleted = 0
      ORDER BY md.created_at DESC
    ''', [patientProfileId]);

    List<MedicalDocumentEntity> result = [];
    for (var doc in docs) {
      final docId = doc['id'] as int;

      // Lấy files
      final files = await db.query(
        'document_files',
        where: 'document_id = ?',
        whereArgs: [docId],
      );
      final fileEntities =
          files.map((f) => DocumentFileModel.fromJson(f)).toList();

      // Lấy tags
      final tagMaps = await db.rawQuery('''
        SELECT t.tag_name FROM tags t
        INNER JOIN document_tags dt ON dt.tag_id = t.id
        WHERE dt.document_id = ?
      ''', [docId]);
      final tagNames =
          tagMaps.map((t) => t['tag_name'] as String).toList();

      result.add(MedicalDocumentModel.fromJson(doc,
          files: fileEntities, tags: tagNames));
    }

    return result;
  }

  @override
  Future<MedicalDocumentEntity?> getDocumentById(int docId) async {
    final db = await _dbHelper.database;

    final docs = await db.rawQuery('''
      SELECT md.*, dc.name as category_name, ua.full_name as created_by_name
      FROM medical_documents md
      LEFT JOIN document_categories dc ON md.category_id = dc.id
      LEFT JOIN user_accounts ua ON md.created_by = ua.id
      WHERE md.id = ?
    ''', [docId]);

    if (docs.isEmpty) return null;

    final doc = docs.first;
    final files = await db.query(
      'document_files',
      where: 'document_id = ?',
      whereArgs: [docId],
    );
    final fileEntities =
        files.map((f) => DocumentFileModel.fromJson(f)).toList();

    final tagMaps = await db.rawQuery('''
      SELECT t.tag_name FROM tags t
      INNER JOIN document_tags dt ON dt.tag_id = t.id
      WHERE dt.document_id = ?
    ''', [docId]);
    final tagNames = tagMaps.map((t) => t['tag_name'] as String).toList();

    return MedicalDocumentModel.fromJson(doc,
        files: fileEntities, tags: tagNames);
  }

  @override
  Future<bool> deleteDocument(int docId) async {
    final db = await _dbHelper.database;
    final count = await db.update(
      'medical_documents',
      {
        'is_deleted': 1,
        'status': 'DELETED',
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [docId],
    );
    return count > 0;
  }

  @override
  Future<List<Map<String, dynamic>>> getDocumentCategories() async {
    final db = await _dbHelper.database;
    return await db.query('document_categories', orderBy: 'id ASC');
  }

  /// Lấy danh sách bệnh nhân
  Future<List<Map<String, dynamic>>> getPatientList() async {
    final db = await _dbHelper.database;
    return await db.query(
      'patient_profiles',
      columns: ['id', 'full_name', 'medical_code', 'dob', 'phone'],
      where: "status = 'ACTIVE'",
      orderBy: 'full_name ASC',
    );
  }

  /// Lấy tất cả tags đã có
  Future<List<String>> getAllTags() async {
    final db = await _dbHelper.database;
    final result = await db.query('tags', orderBy: 'tag_name ASC');
    return result.map((r) => r['tag_name'] as String).toList();
  }
}
