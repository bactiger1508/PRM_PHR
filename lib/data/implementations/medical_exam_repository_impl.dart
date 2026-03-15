import '../../domain/entities/medical_exam_entity.dart';
import '../interfaces/medical_exam_repository.dart';
import '../db/database_helper.dart';
import '../dtos/medical_exam_model.dart';
import 'package:sqflite/sqflite.dart';

class MedicalExamRepositoryImpl implements MedicalExamRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  static const String _categoryName = 'Đơn Khám Bệnh';

  /// Lấy category_id cho "Đơn Khám Bệnh", tạo mới nếu chưa có
  Future<int> _getCategoryId() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'document_categories',
      columns: ['id'],
      where: 'name = ?',
      whereArgs: [_categoryName],
    );
    if (result.isNotEmpty) {
      return result.first['id'] as int;
    }
    // Tạo category nếu chưa tồn tại
    return await db.insert(
      'document_categories',
      {'name': _categoryName, 'description': 'Phiếu khám bệnh, chẩn đoán, đơn thuốc'},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  @override
  Future<int> createMedicalExam(MedicalExamEntity exam) async {
    final db = await _dbHelper.database;
    final categoryId = await _getCategoryId();

    MedicalExamModel model = MedicalExamModel(
      patientProfileId: exam.patientProfileId,
      examDate: exam.examDate,
      diagnosis: exam.diagnosis,
      symptoms: exam.symptoms,
      vitalSigns: exam.vitalSigns,
      prescription: exam.prescription,
      notes: exam.notes,
      followUpDate: exam.followUpDate,
      status: exam.status,
      createdBy: exam.createdBy,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final id = await db.insert('medical_documents', model.toDocumentJson(categoryId));
    return id;
  }

  @override
  Future<List<MedicalExamEntity>> getExamsByPatient(int patientProfileId) async {
    final db = await _dbHelper.database;
    final categoryId = await _getCategoryId();
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT md.*, pp.full_name as patient_name, pp.medical_code as patient_medical_code,
             ua.full_name as created_by_name
      FROM medical_documents md
      LEFT JOIN patient_profiles pp ON md.patient_profile_id = pp.id
      LEFT JOIN user_accounts ua ON md.created_by = ua.id
      WHERE md.patient_profile_id = ? AND md.category_id = ? AND md.is_deleted = 0
      ORDER BY md.created_at DESC
    ''', [patientProfileId, categoryId]);

    return maps.map((json) => MedicalExamModel.fromJson(json)).toList();
  }

  @override
  Future<List<MedicalExamEntity>> getAllExams() async {
    final db = await _dbHelper.database;
    final categoryId = await _getCategoryId();
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT md.*, pp.full_name as patient_name, pp.medical_code as patient_medical_code,
             ua.full_name as created_by_name
      FROM medical_documents md
      LEFT JOIN patient_profiles pp ON md.patient_profile_id = pp.id
      LEFT JOIN user_accounts ua ON md.created_by = ua.id
      WHERE md.category_id = ? AND md.is_deleted = 0
      ORDER BY md.created_at DESC
    ''', [categoryId]);

    return maps.map((json) => MedicalExamModel.fromJson(json)).toList();
  }

  @override
  Future<MedicalExamEntity?> getExamById(int examId) async {
    final db = await _dbHelper.database;
    final categoryId = await _getCategoryId();
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT md.*, pp.full_name as patient_name, pp.medical_code as patient_medical_code,
             ua.full_name as created_by_name
      FROM medical_documents md
      LEFT JOIN patient_profiles pp ON md.patient_profile_id = pp.id
      LEFT JOIN user_accounts ua ON md.created_by = ua.id
      WHERE md.id = ? AND md.category_id = ?
    ''', [examId, categoryId]);

    if (maps.isNotEmpty) {
      return MedicalExamModel.fromJson(maps.first);
    }
    return null;
  }

  @override
  Future<bool> updateExam(MedicalExamEntity exam) async {
    final db = await _dbHelper.database;
    final categoryId = await _getCategoryId();

    final model = MedicalExamModel(
      id: exam.id,
      patientProfileId: exam.patientProfileId,
      examDate: exam.examDate,
      diagnosis: exam.diagnosis,
      symptoms: exam.symptoms,
      vitalSigns: exam.vitalSigns,
      prescription: exam.prescription,
      notes: exam.notes,
      followUpDate: exam.followUpDate,
      status: exam.status,
      createdBy: exam.createdBy,
      updatedAt: DateTime.now(),
    );

    final data = model.toDocumentJson(categoryId);
    data.remove('id');
    data.remove('created_at');

    final count = await db.update(
      'medical_documents',
      data,
      where: 'id = ? AND category_id = ?',
      whereArgs: [exam.id, categoryId],
    );
    return count > 0;
  }

  @override
  Future<bool> deleteExam(int examId) async {
    final db = await _dbHelper.database;
    final categoryId = await _getCategoryId();
    final count = await db.update(
      'medical_documents',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ? AND category_id = ?',
      whereArgs: [examId, categoryId],
    );
    return count > 0;
  }

  /// Lấy danh sách bệnh nhân để chọn khi tạo đơn khám
  Future<List<Map<String, dynamic>>> getPatientList() async {
    final db = await _dbHelper.database;
    return await db.query(
      'patient_profiles',
      columns: ['id', 'full_name', 'medical_code', 'dob', 'phone'],
      where: "status = 'ACTIVE'",
      orderBy: 'full_name ASC',
    );
  }
}
