import '../../core/utils/hash_utils.dart';
import '../../domain/entities/user_entity.dart';
import '../interfaces/auth_repository.dart';
import '../db/database_helper.dart';
import '../dtos/user_model.dart';

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
          'email = ? AND password_hash = ? AND $roleCondition AND status = ?',
      whereArgs: [email, passwordHash, 'ACTIVE'],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromJson(maps.first);
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

    return count > 0;
  }

  @override
  Future<int> createStaffAccount(
    UserEntity staffUser,
    String defaultPassword,
  ) async {
    final db = await _dbHelper.database;
    final model = UserModel(
      email: staffUser.email,
      phone: staffUser.phone,
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
  Future<int> createCustomerAccount(
    String email,
    String defaultPassword,
    String? fullName,
  ) async {
    final db = await _dbHelper.database;

    // Check if account already exists
    final existing = await db.query(
      'user_accounts',
      where: 'email = ? AND role = ?',
      whereArgs: [email, 'CUSTOMER'],
    );

    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }

    final model = UserModel(
      email: email,
      fullName: fullName,
      passwordHash: HashUtils.hashPassword(defaultPassword),
      role: 'CUSTOMER',
      status: 'ACTIVE',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await db.insert('user_accounts', model.toJson());
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
