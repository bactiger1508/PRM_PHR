import 'dart:math';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/exceptions/patient_profile_locked_exception.dart';
import '../../core/utils/hash_utils.dart';
import '../../domain/entities/user_entity.dart';
import '../interfaces/auth_repository.dart';
import '../db/database_helper.dart';
import '../dtos/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepositoryImpl implements AuthRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<UserEntity?> login(
    String email,
    String password,
    bool isCustomer,
  ) async {
    final db = await _dbHelper.database;
    final passwordHash = HashUtils.hashPassword(password);

    String roleCondition = isCustomer
        ? "role = 'CUSTOMER'"
        : "role IN ('STAFF', 'ADMIN')";

    final List<Map<String, dynamic>> maps = await db.query(
      'user_accounts',
      where:
          '(email = ? OR phone = ?) AND password_hash = ? AND $roleCondition',
      whereArgs: [email, email, passwordHash],
    );

    if (maps.isNotEmpty) {
      if (maps.first['status'] == 'LOCKED' || maps.first['status'] == 'INACTIVE') {
        throw Exception('ACCOUNT_LOCKED');
      }
      if (maps.first['status'] != 'ACTIVE') {
        return null;
      }
      final user = UserModel.fromJson(maps.first);
      if (isCustomer && user.id != null) {
        final lockRows = await db.rawQuery('''
          SELECT pp.status FROM patient_profiles pp
          INNER JOIN family_access fa ON fa.patient_profile_id = pp.id
          WHERE fa.customer_account_id = ? AND fa.relationship = ?
        ''', [user.id!, 'Bản thân']);
        if (lockRows.isNotEmpty && lockRows.first['status'] == 'LOCKED') {
          throw PatientProfileLockedException();
        }
      }
      return user;
    }
    return null;
  }

  @override
  Future<bool> changePassword(int userId, String newPassword) async {
    final db = await _dbHelper.database;
    final passwordHash = HashUtils.hashPassword(newPassword);

    final count = await db.update(
      'user_accounts',
      {
        'password_hash': passwordHash,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (count > 0) {
      await db.insert('system_notifications', {
        'user_id': userId,
        'title': 'Thay đổi mật khẩu',
        'message': 'Mật khẩu của bạn vừa được đổi mới thành công. Nếu không phải bạn, hãy báo ngay cho bộ phận CSKH.',
        'type': 'SECURITY',
        'is_read': 0,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    }

    return count > 0;
  }

  @override
  Future<int> createStaffAccount(
    UserEntity staffUser,
    String defaultPassword,
  ) async {
    final db = await _dbHelper.database;
    final email = (staffUser.email != null && staffUser.email!.trim().isNotEmpty) ? staffUser.email!.trim() : null;
    final phone = (staffUser.phone != null && staffUser.phone!.trim().isNotEmpty) ? staffUser.phone!.trim() : null;

    final model = UserModel(
      email: email,
      phone: phone,
      fullName: staffUser.fullName,
      passwordHash: HashUtils.hashPassword(defaultPassword),
      role: staffUser.role,
      status: 'ACTIVE',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await db.insert('user_accounts', model.toJson());
  }

  @override
  Future<List<UserEntity>> getAllStaffs() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_accounts',
      where: "role IN ('STAFF', 'ADMIN')",
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => UserModel.fromJson(map)).toList();
  }

  @override
  Future<List<UserEntity>> getAllUsers() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM user_accounts
      ORDER BY
        CASE role
          WHEN 'ADMIN' THEN 1
          WHEN 'STAFF' THEN 2
          WHEN 'CUSTOMER' THEN 3
          ELSE 4
        END,
        created_at DESC
    ''');
    return maps.map((map) => UserModel.fromJson(map)).toList();
  }

  @override
  Future<bool> updateStaff(int userId, {String? fullName, String? email, String? phone, String? status}) async {
    final db = await _dbHelper.database;
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
    if (fullName != null) updates['full_name'] = fullName.trim();
    if (email != null) updates['email'] = email.trim();
    if (phone != null) updates['phone'] = phone.trim().isEmpty ? null : phone.trim();
    if (status != null) updates['status'] = status;

    final count = await db.update(
      'user_accounts',
      updates,
      where: 'id = ?',
      whereArgs: [userId],
    );
    return count > 0;
  }

  @override
  Future<bool> deleteStaff(int userId) async {
    final db = await _dbHelper.database;
    final count = await db.delete(
      'user_accounts',
      where: 'id = ?',
      whereArgs: [userId],
    );
    return count > 0;
  }

  @override
  Future<int> createCustomerAccount(
    String email,
    String defaultPassword,
    String? fullName,
  ) async {
    final db = await _dbHelper.database;

    return await db.transaction((txn) async {
      // 1. Kiểm tra tài khoản đã tồn tại chưa
      final existing = await txn.query(
        'user_accounts',
        where: 'email = ? AND role = ?',
        whereArgs: [email, 'CUSTOMER'],
      );

      int accountId;
      if (existing.isNotEmpty) {
        accountId = existing.first['id'] as int;
      } else {
        final model = UserModel(
          email: email,
          fullName: fullName,
          passwordHash: HashUtils.hashPassword(defaultPassword),
          role: 'CUSTOMER',
          status: 'ACTIVE',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        accountId = await txn.insert('user_accounts', model.toJson());
        // Tự động gán family_id bằng chính id tài khoản nếu là tài khoản mới
        await txn.update('user_accounts', {'family_id': accountId}, where: 'id = ?', whereArgs: [accountId]);
      }

      // 2. Kiểm tra xem đã có liên kết "Bản thân" chưa
      final selfLink = await txn.query('family_access',
          where: 'customer_account_id = ? AND relationship = ?',
          whereArgs: [accountId, 'Bản thân']);

      if (selfLink.isEmpty) {
        int patientId = -1;
        final prefs = await SharedPreferences.getInstance();
        final customPrefix = prefs.getString('medical_code_prefix') ?? 'PHR';
        final random = Random();
        for (var attempt = 0; attempt < 64; attempt++) {
          final medicalCode =
              '$customPrefix-${DateFormat('ddMMyyyy').format(DateTime.now())}-${random.nextInt(10000).toString().padLeft(4, '0')}';
          try {
            patientId = await txn.insert('patient_profiles', {
              'medical_code': medicalCode,
              'full_name': fullName ?? email.split('@')[0],
              'email': email,
              'created_by': accountId,
              'family_id': accountId,
              'created_at': DateTime.now().millisecondsSinceEpoch,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            });
            break;
          } catch (e) {
            if (e is DatabaseException && e.isUniqueConstraintError()) {
              continue;
            }
            rethrow;
          }
        }
        if (patientId < 0) {
          throw Exception('Không tạo được mã y tế duy nhất. Vui lòng thử lại.');
        }

        await txn.insert('family_access', {
          'customer_account_id': accountId,
          'patient_profile_id': patientId,
          'relationship': 'Bản thân',
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
      }

      return accountId;
    });
  }

  @override
  Future<UserEntity?> findByEmail(String email) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_accounts',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromJson(maps.first);
    }
    return null;
  }

  @override
  Future<UserEntity?> findById(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_accounts',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromJson(maps.first);
    }
    return null;
  }

  @override
  Future<int?> otpCooldownRemainingSeconds(String email, String purpose,
      {int cooldownSeconds = 60}) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'otp_codes',
      columns: ['created_at'],
      where: 'email = ? AND purpose = ?',
      whereArgs: [email, purpose],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final createdMs = rows.first['created_at'] as int?;
    if (createdMs == null) return null;
    final elapsed = DateTime.now().millisecondsSinceEpoch - createdMs;
    final cooldownMs = cooldownSeconds * 1000;
    if (elapsed >= cooldownMs) return null;
    return ((cooldownMs - elapsed + 999) ~/ 1000);
  }

  @override
  Future<void> saveOtp(String email, String otpCode, String purpose) async {
    final db = await _dbHelper.database;

    // Invalidate old OTPs for same email+purpose
    await db.update(
      'otp_codes',
      {'is_used': 1},
      where: 'email = ? AND purpose = ? AND is_used = 0',
      whereArgs: [email, purpose],
    );

    await db.insert('otp_codes', {
      'email': email,
      'otp_code': otpCode,
      'purpose': purpose,
      'expires_at':
          DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch,
      'is_used': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<bool> verifyOtp(String email, String otpCode, String purpose) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await db.query(
      'otp_codes',
      where:
          'email = ? AND otp_code = ? AND purpose = ? AND is_used = 0 AND expires_at > ?',
      whereArgs: [email, otpCode, purpose, now],
    );

    if (maps.isNotEmpty) {
      // Mark as used
      await db.update(
        'otp_codes',
        {'is_used': 1},
        where: 'id = ?',
        whereArgs: [maps.first['id']],
      );
      return true;
    }
    return false;
  }

  @override
  Future<bool> resetPasswordByEmail(String email, String newPassword) async {
    final db = await _dbHelper.database;
    final passwordHash = HashUtils.hashPassword(newPassword);

    final count = await db.update(
      'user_accounts',
      {
        'password_hash': passwordHash,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'email = ?',
      whereArgs: [email],
    );

    return count > 0;
  }
}
