import 'package:flutter/material.dart';
import '../../core/utils/hash_utils.dart';
import 'package:sqflite/sqflite.dart';
import '../data/db/database_helper.dart';

class AdminSetupViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMsg;
  String? get errorMsg => _errorMsg;

  bool _isSuccess = false;
  bool get isSuccess => _isSuccess;

  /// Setup the first Admin account with username.
  Future<bool> setupInitialAdmin({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _errorMsg = null;
    _isSuccess = false;
    notifyListeners();

    try {
      final hasAdmin = await _dbHelper.hasAdminAccount();
      if (hasAdmin) {
        _errorMsg = 'Hệ thống đã có tài khoản Quản trị viên.';
        return false;
      }

      final db = await _dbHelper.database;
      final adminHash = HashUtils.hashPassword(password);

      await db.insert(
        'user_accounts',
        {
          'email': username, // Store username in email column
          'full_name': 'Quản trị viên',
          'password_hash': adminHash,
          'role': 'ADMIN',
          'status': 'ACTIVE',
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.fail,
      );

      _isSuccess = true;
      return true;
    } catch (e) {
      _errorMsg = 'Lỗi thiết lập: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
