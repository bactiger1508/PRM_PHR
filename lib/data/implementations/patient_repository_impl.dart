import 'dart:math';
import 'package:intl/intl.dart';
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

    // 1. Tạo tiền tố mã dựa trên Ngày sinh và Ngày tạo
    String cleanDob = (patient.dob ?? '').replaceAll('/', '');
    if (cleanDob.isEmpty) cleanDob = '00000000';
    String today = DateFormat('ddMMyyyy').format(DateTime.now());
    String prefix = 'PHR-$cleanDob-$today';

    // 2. Kiểm tra số thứ tự trong DB
    final List<Map<String, dynamic>> existing = await db.query(
      'patient_profiles',
      columns: ['medical_code'],
      where: 'medical_code LIKE ?',
      whereArgs: ['$prefix%'],
    );

    int sequence = existing.length + 1;
    String sequenceStr = sequence.toString().padLeft(2, '0');
    String medicalCode = '$prefix-$sequenceStr';

    String defaultPasswordHash = HashUtils.hashPassword('123456');
    int now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      // CHỈ tạo tài khoản User nếu có cung cấp Email
      if (patient.email != null && patient.email!.isNotEmpty) {
        Map<String, dynamic> userMap = {
          'email': patient.email,
          'full_name': patient.fullName,
          'password_hash': defaultPasswordHash,
          'role': 'CUSTOMER',
          'status': 'ACTIVE',
          'created_at': now,
          'updated_at': now,
        };

        try {
          await txn.insert('user_accounts', userMap);
        } catch (e) {
          if (e is DatabaseException && e.isUniqueConstraintError()) {
            final List<Map<String, dynamic>> res = await txn.query(
              'patient_profiles',
              columns: ['medical_code'],
              where: 'email = ?',
              whereArgs: [patient.email],
            );
            if (res.isNotEmpty) {
              String existingCode = res.first['medical_code'];
              throw Exception('Email này đã được đăng ký. Mã Y Tế của họ là: $existingCode');
            }
            throw Exception('Email này đã được đăng ký tài khoản.');
          }
          rethrow;
        }
      }

      // Luôn tạo Hồ sơ Bệnh nhân (Patient Profile)
      PatientModel model = PatientModel(
        medicalCode: medicalCode,
        fullName: patient.fullName,
        dob: patient.dob,
        phone: patient.phone,
        email: patient.email,
        status: patient.status,
        createdBy: patient.createdBy,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await txn.insert('patient_profiles', model.toJson());
    });

    // CHỈ gửi email nếu có cung cấp Email
    if (patient.email != null && patient.email!.isNotEmpty) {
      _emailService.sendWelcomeEmail(
        toEmail: patient.email!,
        defaultPassword: '123456',
        patientName: patient.fullName,
      );
    }

    return medicalCode;
  }

  @override
  Future<PatientEntity?> getPatientByEmail(String email) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'patient_profiles',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return PatientModel.fromJson(maps.first);
    }
    return null;
  }

  @override
  Future<bool> updatePatientProfile(int patientId, {String? dob, String? phone}) async {
    final db = await _dbHelper.database;
    final Map<String, dynamic> values = {
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
    if (dob != null) values['dob'] = dob;
    if (phone != null) values['phone'] = phone;

    final count = await db.update(
      'patient_profiles',
      values,
      where: 'id = ?',
      whereArgs: [patientId],
    );
    return count > 0;
  }
}
