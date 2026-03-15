import 'dart:math';
import 'package:intl/intl.dart';
import 'package:phrprmgroupproject/domain/entities/user_entity.dart';
import '../../core/utils/hash_utils.dart';
import '../../core/services/email_service.dart';
import '../../domain/entities/patient_entity.dart';
import '../interfaces/patient_repository.dart';
import '../db/database_helper.dart';
import '../dtos/patient_model.dart';
import 'package:sqflite/sqflite.dart';

class PatientRepositoryImpl implements PatientRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final EmailService _emailService = EmailService();

  @override
  Future<String> createPatientAndAccount(PatientEntity patient) async {
    final db = await _dbHelper.database;

    String cleanDob = (patient.dob ?? '').replaceAll('/', '');
    if (cleanDob.isEmpty) cleanDob = '00000000';
    String today = DateFormat('ddMMyyyy').format(DateTime.now());
    String prefix = 'PHR-$cleanDob-$today';
    final existing = await db.query('patient_profiles', columns: ['medical_code'], where: 'medical_code LIKE ?', whereArgs: ['$prefix%']);
    int sequence = existing.length + 1;
    String medicalCode = '$prefix-${sequence.toString().padLeft(2, '0')}';

    final String? email = (patient.email != null && patient.email!.trim().isNotEmpty) ? patient.email!.trim() : null;
    final String? phone = (patient.phone != null && patient.phone!.trim().isNotEmpty) ? patient.phone!.trim() : null;

    int? userId;

    await db.transaction((txn) async {
      if (email != null || phone != null) {
        Map<String, dynamic> userMap = {
          'email': email,
          'phone': phone,
          'full_name': patient.fullName,
          'password_hash': HashUtils.hashPassword('123456'),
          'role': 'CUSTOMER',
          'status': 'ACTIVE',
          'created_at': DateTime.now().millisecondsSinceEpoch,
        };
        try {
          userId = await txn.insert('user_accounts', userMap, conflictAlgorithm: ConflictAlgorithm.fail);
        } catch (e) {
          if (e is DatabaseException && e.isUniqueConstraintError()) {
            if (email != null) {
              final emailConflict = await txn.query('user_accounts', where: 'email = ?', whereArgs: [email]);
              if (emailConflict.isNotEmpty) {
                final res = await txn.query('patient_profiles', columns: ['medical_code'], where: 'email = ?', whereArgs: [email]);
                throw Exception(res.isNotEmpty 
                  ? 'Email này đã được đăng ký hồ sơ. Mã Y Tế: ${res.first['medical_code']}' 
                  : 'Email này đã được sử dụng cho một tài khoản khác.');
              }
            }
            throw Exception('Thông tin Email hoặc Số điện thoại đã tồn tại.');
          }
          rethrow;
        }
      }

      PatientModel model = PatientModel(
        medicalCode: medicalCode,
        fullName: patient.fullName,
        dob: patient.dob,
        phone: patient.phone,
        email: patient.email,
        status: 'ACTIVE',
        createdBy: patient.createdBy,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final patientId = await txn.insert('patient_profiles', model.toJson());

      if (userId != null) {
        await txn.insert('family_access', {
          'customer_account_id': userId,
          'patient_profile_id': patientId,
          'relationship': 'Bản thân',
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
      }
    });

    if (patient.email != null && patient.email!.isNotEmpty) {
      _emailService.sendWelcomeEmail(toEmail: patient.email!, defaultPassword: '123456', patientName: patient.fullName);
    }

    return medicalCode;
  }

  @override
  Future<String> generateAccessCode(String medicalCode) async {
    final db = await _dbHelper.database;
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    String code = '';
    bool isUnique = false;

    while (!isUnique) {
      code = String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
      final existing = await db.query('patient_profiles', columns: ['id'], where: 'access_code = ?', whereArgs: [code]);
      if (existing.isEmpty) isUnique = true;
    }

    await db.update('patient_profiles', {'access_code': code, 'updated_at': DateTime.now().millisecondsSinceEpoch}, where: 'medical_code = ?', whereArgs: [medicalCode]);
    return code;
  }

  @override
  Future<bool> linkFamilyMember(int customerId, String medicalCode, String accessCode, String relationship) async {
    final db = await _dbHelper.database;
    
    final patients = await db.query('patient_profiles', where: 'medical_code = ? AND access_code = ?', whereArgs: [medicalCode, accessCode]);
    if (patients.isEmpty) throw Exception('Mã y tế hoặc mã truy cập không chính xác.');
    
    final linkedPatientId = patients.first['id'] as int;
    final linkedPatientEmail = patients.first['email'] as String?;
    
    await db.transaction((txn) async {
      // 1. Liên kết cơ bản
      await txn.insert('family_access', {
        'customer_account_id': customerId,
        'patient_profile_id': linkedPatientId,
        'relationship': relationship,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // 2. Nếu là Vợ/Chồng, thực hiện gộp gia đình
      if (relationship == 'Vợ/Chồng' && linkedPatientEmail != null) {
        final linkedUsers = await txn.query('user_accounts', where: 'email = ?', whereArgs: [linkedPatientEmail]);
        if (linkedUsers.isNotEmpty) {
          final linkedCustomerId = linkedUsers.first['id'] as int;

          // A. Lấy tất cả hồ sơ mà Linker (Bố) đang quản lý (ngoại trừ bản thân và Vợ)
          final linkerDocs = await txn.query('family_access', where: 'customer_account_id = ?', whereArgs: [customerId]);
          for (var doc in linkerDocs) {
            int pid = doc['patient_profile_id'] as int;
            if (pid != linkedPatientId) {
              await txn.insert('family_access', {
                'customer_account_id': linkedCustomerId,
                'patient_profile_id': pid,
                'relationship': doc['relationship'],
                'created_at': DateTime.now().millisecondsSinceEpoch,
              }, conflictAlgorithm: ConflictAlgorithm.ignore);
            }
          }

          // B. Lấy tất cả hồ sơ mà Linked Person (Mẹ) đang quản lý và chia sẻ cho Bố
          final otherDocs = await txn.query('family_access', where: 'customer_account_id = ?', whereArgs: [linkedCustomerId]);
          // Tìm ID hồ sơ của chính Bố để tránh tự liên kết mình là con
          final selfProfile = await txn.query('family_access', 
            where: 'customer_account_id = ? AND relationship = ?', 
            whereArgs: [customerId, 'Bản thân']);
          int? linkerPatientId = selfProfile.isNotEmpty ? selfProfile.first['patient_profile_id'] as int : null;

          for (var doc in otherDocs) {
            int pid = doc['patient_profile_id'] as int;
            if (pid != linkerPatientId) {
              await txn.insert('family_access', {
                'customer_account_id': customerId,
                'patient_profile_id': pid,
                'relationship': doc['relationship'],
                'created_at': DateTime.now().millisecondsSinceEpoch,
              }, conflictAlgorithm: ConflictAlgorithm.ignore);
            }
          }

          // C. Tạo liên kết ngược (Mẹ liên kết lại Bố là Vợ/Chồng)
          if (linkerPatientId != null) {
            await txn.insert('family_access', {
              'customer_account_id': linkedCustomerId,
              'patient_profile_id': linkerPatientId,
              'relationship': 'Vợ/Chồng',
              'created_at': DateTime.now().millisecondsSinceEpoch,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      }
    });
    
    return true;
  }

  @override
  Future<List<Map<String, dynamic>>> getFamilyMembers(int customerId) async {
    final db = await _dbHelper.database;
    const query = '''
      SELECT p.*, f.relationship, f.created_at as linked_at
      FROM patient_profiles p
      JOIN family_access f ON p.id = f.patient_profile_id
      WHERE f.customer_account_id = ?
      ORDER BY CASE WHEN f.relationship = 'Bản thân' THEN 0 ELSE 1 END, f.created_at DESC
    ''';
    return await db.rawQuery(query, [customerId]);
  }

  @override
  Future<PatientEntity?> getPatientByPhoneOrEmail({String? phone, String? email}) async {
    final db = await _dbHelper.database;
    if ((phone == null || phone.isEmpty) && (email == null || email.isEmpty)) return null;
    List<String> conds = []; List<dynamic> args = [];
    if (email != null && email.isNotEmpty) { conds.add('email = ?'); args.add(email); }
    if (phone != null && phone.isNotEmpty) { conds.add('phone = ?'); args.add(phone); }
    final maps = await db.query('patient_profiles', where: conds.join(' OR '), whereArgs: args);
    return maps.isNotEmpty ? PatientModel.fromJson(maps.first) : null;
  }

  @override
  Future<bool> updatePatientProfile(int patientId, {String? dob, String? phone}) async {
    final db = await _dbHelper.database;
    final Map<String, dynamic> values = {'updated_at': DateTime.now().millisecondsSinceEpoch};
    if (dob != null) values['dob'] = dob;
    if (phone != null) values['phone'] = phone;
    final count = await db.update('patient_profiles', values, where: 'id = ?', whereArgs: [patientId]);
    return count > 0;
  }

  @override
  Future<DashboardStats> getStats() async {
    return await DatabaseHelper.instance.getDashboardStats();
  }

  @override
  Future<List<UserEntity>> getAllCustomers() async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'user_accounts',
      where: 'role = ?',
      whereArgs: ['CUSTOMER'],
      orderBy: 'id DESC',
    );

    return maps.map((map) => UserEntity(
      id: map['id'],
      fullName: map['full_name'],
      email: map['email'],
      phone: map['phone'],
      role: map['role'],
      status: map['status'],
      avatar: map['avatar'],
    )).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getDocumentsByPatientId(int patientId) async {
    final db = await DatabaseHelper.instance.database;
    final String sql = '''
      SELECT 
        md.*, 
        dc.name as category_name 
      FROM medical_documents md
      LEFT JOIN document_categories dc ON md.category_id = dc.id
      WHERE md.patient_profile_id = ? AND md.is_deleted = 0
      ORDER BY md.id DESC
    ''';

    return await db.rawQuery(sql, [patientId]);
  Future<List<Map<String, dynamic>>> getRecentPatients({int limit = 3}) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> result = await db.query(
      'patient_profiles',
      orderBy: 'id DESC',
      // limit: limit,
    );

    return result;
  }
}
