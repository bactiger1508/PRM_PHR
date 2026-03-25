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

    // Ghi nhật ký tạo tài liệu
    final userQuery = await db.query('user_accounts', columns: ['full_name'], where: 'id = ?', whereArgs: [doc.createdBy]);
    final userName = userQuery.isNotEmpty ? userQuery.first['full_name'] as String : 'Không rõ';

    await db.insert('audit_logs', {
      'user_id': doc.createdBy,
      'action': 'Tạo tài liệu y tế',
      'entity_type': 'medical_documents',
      'entity_id': id,
      'details': 'Người dùng $userName đã tạo tài liệu: ${doc.title}',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    if (doc.status == 'SAVED') {
      await _notifyCustomerDocument(db, doc.patientProfileId, doc.createdBy ?? 0, doc.title ?? 'Không tên', true);
    }

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

    final normalized = tagName.trim().toLowerCase();
    if (normalized.isEmpty) return;

    final existingTags = await db.rawQuery(
      'SELECT id, tag_name FROM tags WHERE LOWER(tag_name) = ?',
      [normalized],
    );

    int tagId;
    if (existingTags.isNotEmpty) {
      tagId = existingTags.first['id'] as int;
    } else {
      tagId = await db.insert('tags', {
        'tag_name': normalized,
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
      SELECT md.*, dc.name as category_name, ua.full_name as created_by_name,
             pp.full_name as patient_name, pp.medical_code
      FROM medical_documents md
      LEFT JOIN document_categories dc ON md.category_id = dc.id
      LEFT JOIN user_accounts ua ON md.created_by = ua.id
      LEFT JOIN patient_profiles pp ON md.patient_profile_id = pp.id
      WHERE md.patient_profile_id = ? AND md.is_deleted = 0
        AND (pp.status IS NULL OR pp.status != 'LOCKED')
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
  Future<MedicalDocumentEntity?> getDocumentById(int docId,
      {bool includeDeleted = false}) async {
    final db = await _dbHelper.database;

    final deletedClause = includeDeleted ? '' : 'AND md.is_deleted = 0';
    final docs = await db.rawQuery('''
      SELECT md.*, dc.name as category_name, ua.full_name as created_by_name
      FROM medical_documents md
      LEFT JOIN document_categories dc ON md.category_id = dc.id
      LEFT JOIN user_accounts ua ON md.created_by = ua.id
      WHERE md.id = ? $deletedClause
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
  Future<bool> deleteDocument(int docId, int performedByUserId) async {
    final db = await _dbHelper.database;
    final userQuery = await db.query('user_accounts', columns: ['full_name'], where: 'id = ?', whereArgs: [performedByUserId]);
    final userName = userQuery.isNotEmpty ? userQuery.first['full_name'] as String : 'Không rõ';

    final existing = await db.query(
      'medical_documents',
      columns: ['status'],
      where: 'id = ?',
      whereArgs: [docId],
    );
    final statusBefore =
        existing.isNotEmpty ? existing.first['status'] as String? : null;

    final count = await db.update(
      'medical_documents',
      {
        'is_deleted': 1,
        'status': 'DELETED',
        'status_before_soft_delete':
            (statusBefore != null && statusBefore != 'DELETED')
                ? statusBefore
                : null,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [docId],
    );

    if (count > 0) {
      await db.insert('audit_logs', {
        'user_id': performedByUserId,
        'action': 'Xóa tài liệu y tế',
        'entity_type': 'medical_documents',
        'entity_id': docId,
        'details': 'Người dùng $userName đã chuyển tài liệu ID: $docId vào thùng rác.',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }

    return count > 0;
  }

  @override
  Future<bool> restoreDocument(int docId, int performedByUserId) async {
    final db = await _dbHelper.database;
    final userQuery = await db.query('user_accounts', columns: ['full_name'], where: 'id = ?', whereArgs: [performedByUserId]);
    final userName = userQuery.isNotEmpty ? userQuery.first['full_name'] as String : 'Không rõ';

    final row = await db.query(
      'medical_documents',
      columns: ['status_before_soft_delete'],
      where: 'id = ?',
      whereArgs: [docId],
    );
    final savedStatus = row.isNotEmpty
        ? row.first['status_before_soft_delete'] as String?
        : null;
    final restoredStatus = (savedStatus != null &&
            savedStatus.isNotEmpty &&
            savedStatus != 'DELETED')
        ? savedStatus
        : 'SAVED';

    final count = await db.update(
      'medical_documents',
      {
        'is_deleted': 0,
        'status': restoredStatus,
        'status_before_soft_delete': null,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [docId],
    );

    if (count > 0) {
      await db.insert('audit_logs', {
        'user_id': performedByUserId,
        'action': 'Khôi phục tài liệu y tế',
        'entity_type': 'medical_documents',
        'entity_id': docId,
        'details': 'Người dùng $userName đã khôi phục tài liệu ID: $docId.',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }

    return count > 0;
  }

  @override
  Future<bool> hardDeleteDocument(int docId, int performedByUserId) async {
    final db = await _dbHelper.database;
    final userQuery = await db.query('user_accounts', columns: ['full_name'], where: 'id = ?', whereArgs: [performedByUserId]);
    final userName = userQuery.isNotEmpty ? userQuery.first['full_name'] as String : 'Không rõ';

    // 1. Xóa file vật lý
    // ... nội dung giữ nguyên ...
    final files = await db.query('document_files',
        where: 'document_id = ?', whereArgs: [docId]);
    for (var f in files) {
      final path = f['file_path'] as String;
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }

    // 2. Xóa liên kết trong DB
    await db.delete('document_files',
        where: 'document_id = ?', whereArgs: [docId]);
    await db.delete('document_tags',
        where: 'document_id = ?', whereArgs: [docId]);

    // 3. Xóa document chính
    final count =
        await db.delete('medical_documents', where: 'id = ?', whereArgs: [docId]);

    if (count > 0) {
      await db.insert('audit_logs', {
        'user_id': performedByUserId,
        'action': 'Xóa vĩnh viễn tài liệu',
        'entity_type': 'medical_documents',
        'entity_id': docId,
        'details': 'Người dùng $userName đã xóa vĩnh viễn tài liệu ID: $docId.',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }

    return count > 0;
  }

  /// Dọn sạch thùng rác cho nhân viên
  @override
  Future<bool> clearTrash(int staffId) async {
    final db = await _dbHelper.database;
    final deletedDocs = await db.query(
      'medical_documents',
      columns: ['id'],
      where: 'created_by = ? AND is_deleted = 1',
      whereArgs: [staffId],
    );

    bool allSuccess = true;
    for (var doc in deletedDocs) {
      final success = await hardDeleteDocument(doc['id'] as int, staffId);
      if (!success) allSuccess = false;
    }
    return allSuccess;
  }

  /// Cập nhật tài liệu
  @override
  Future<bool> updateDocument(MedicalDocumentEntity doc, int performedByUserId) async {
    final db = await _dbHelper.database;
    final userQuery = await db.query('user_accounts', columns: ['full_name'], where: 'id = ?', whereArgs: [performedByUserId]);
    final userName = userQuery.isNotEmpty ? userQuery.first['full_name'] as String : 'Không rõ';

    final count = await db.update(
      'medical_documents',
      {
        'category_id': doc.categoryId,
        'title': doc.title,
        'notes': doc.notes,
        'record_date': doc.recordDate,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [doc.id],
    );

    if (count > 0) {
      // Ghi nhật ký cập nhật tài liệu
      await db.insert('audit_logs', {
        'user_id': performedByUserId,
        'action': 'Cập nhật tài liệu y tế',
        'entity_type': 'medical_documents',
        'entity_id': doc.id,
        'details': 'Người dùng $userName đã cập nhật tài liệu: ${doc.title}',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }

    return count > 0;
  }

  /// Cập nhật tags cho tài liệu
  @override
  Future<void> updateTagsForDocument(int docId, List<String> newTags) async {
    final db = await _dbHelper.database;
    
    // Xóa hết tags cũ của document này
    await db.delete(
      'document_tags',
      where: 'document_id = ?',
      whereArgs: [docId],
    );

    // Thêm tags mới
    for (var tag in newTags) {
      await addTagToDocument(docId, tag);
    }
  }

  /// Cập nhật danh sách files cho tài liệu
  @override
  Future<void> updateFilesForDocument(int docId, List<File> newFiles) async {
    final db = await _dbHelper.database;
    
    // Lấy danh sách files hiện có trong DB
    final existingFiles = await db.query(
      'document_files',
      where: 'document_id = ?',
      whereArgs: [docId],
    );

    final existingPaths = existingFiles.map((f) => f['file_path'] as String).toList();
    final newPaths = newFiles.map((f) => f.path).toList();

    // 1. Xóa các file không còn trong danh sách mới
    for (var oldPath in existingPaths) {
      if (!newPaths.contains(oldPath)) {
        await db.delete(
          'document_files',
          where: 'document_id = ? AND file_path = ?',
          whereArgs: [docId, oldPath],
        );
        // Có thể cân nhắc xóa file vật lý ở đây nếu cần
      }
    }

    // 2. Thêm các file mới (chưa có trong DB)
    for (var file in newFiles) {
      if (!existingPaths.contains(file.path)) {
        final fileEntity = DocumentFileEntity(
          filePath: file.path,
          fileType: _getFileType(file.path),
          fileSize: await file.length(),
        );
        await addFileToDocument(docId, fileEntity);
      }
    }
  }

  String _getFileType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  /// Lấy tài liệu do nhân viên tạo (Bao gồm cả đã xóa để có thể khôi phục)
  @override
  Future<List<MedicalDocumentEntity>> getDocumentsByCreator(int staffId) async {
    final db = await _dbHelper.database;

    final docs = await db.rawQuery('''
      SELECT md.*, dc.name as category_name, ua.full_name as created_by_name,
             pp.full_name as patient_name, pp.medical_code
      FROM medical_documents md
      LEFT JOIN document_categories dc ON md.category_id = dc.id
      LEFT JOIN user_accounts ua ON md.created_by = ua.id
      LEFT JOIN patient_profiles pp ON md.patient_profile_id = pp.id
      WHERE md.created_by = ?
      ORDER BY md.created_at DESC
    ''', [staffId]);

    List<MedicalDocumentEntity> result = [];
    for (var doc in docs) {
      final docId = doc['id'] as int;

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
      final tagNames =
          tagMaps.map((t) => t['tag_name'] as String).toList();

      result.add(MedicalDocumentModel.fromJson(doc,
          files: fileEntities, tags: tagNames));
    }

    return result;
  }

  @override
  Future<List<Map<String, dynamic>>> getDocumentCategories() async {
    final db = await _dbHelper.database;
    return await db.query('document_categories', orderBy: 'id ASC');
  }

  @override
  Future<int> createDocumentCategory(String name) async {
    final db = await _dbHelper.database;
    // Check if category already exists
    final existing = await db.query(
      'document_categories',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }
    // Insert new category
    return await db.insert('document_categories', {
      'name': name,
      'description': 'Danh mục tùy chỉnh',
    });
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

  @override
  Future<bool> updateDocumentStatus(int docId, String newStatus, int performedByUserId) async {
    final db = await _dbHelper.database;
    final userQuery = await db.query('user_accounts', columns: ['full_name'], where: 'id = ?', whereArgs: [performedByUserId]);
    final userName = userQuery.isNotEmpty ? userQuery.first['full_name'] as String : 'Không rõ';

    final count = await db.update(
      'medical_documents',
      {
        'status': newStatus,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [docId],
    );

    if (count > 0) {
      await db.insert('audit_logs', {
        'user_id': performedByUserId,
        'action': 'Cập nhật trạng thái tài liệu',
        'entity_type': 'medical_documents',
        'entity_id': docId,
        'details': 'Người dùng $userName đã cập nhật trạng thái tài liệu ID: $docId sang $newStatus.',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      if (newStatus == 'SAVED') {
        final docQuery = await db.query('medical_documents', where: 'id = ?', whereArgs: [docId]);
        if (docQuery.isNotEmpty) {
          final doc = docQuery.first;
          await _notifyCustomerDocument(db, doc['patient_profile_id'] as int, doc['created_by'] as int, doc['title'] as String, false);
        }
      }
    }

    return count > 0;
  }

  Future<void> _notifyCustomerDocument(dynamic db, int patientProfileId, int staffId, String title, bool isNew) async {
    try {
      final staffQuery = await db.query('user_accounts', columns: ['full_name'], where: 'id = ?', whereArgs: [staffId]);
      final staffName = staffQuery.isNotEmpty ? staffQuery.first['full_name'] as String : 'Nhân viên y tế';
      
      final customerQuery = await db.query('family_access', columns: ['customer_account_id'], where: 'patient_profile_id = ? AND status = ?', whereArgs: [patientProfileId, 'ACTIVE']);
      
      final String notifyTitle = isNew ? 'Hồ sơ y tế mới' : 'Cập nhật hồ sơ y tế';
      
      final now = DateTime.now();
      final dateStr = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
      
      final String message = isNew
          ? 'Bác sĩ $staffName vừa thêm một tài liệu mới ($title) vào hồ sơ của bạn.'
          : 'Tài liệu chẩn đoán ngày $dateStr của bạn vừa được cập nhật/chỉnh sửa bởi bác sĩ $staffName.';

      for (var row in customerQuery) {
        final customerId = row['customer_account_id'] as int;
        await db.insert('system_notifications', {
          'user_id': customerId,
          'title': notifyTitle,
          'message': message,
          'type': 'DOCUMENT',
          'is_read': 0,
          'created_at': now.millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      // Ignore notification failures to avoid blocking the document flow
    }
  }
}
