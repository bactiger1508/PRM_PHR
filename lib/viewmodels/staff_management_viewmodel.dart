import 'package:flutter/material.dart';
import '../data/interfaces/auth_repository.dart';
import '../data/implementations/auth_repository_impl.dart';
import '../domain/entities/user_entity.dart';
import '../domain/entities/staff_stats.dart';
import '../data/db/database_helper.dart';

class StaffManagementViewModel extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepositoryImpl();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMsg;
  String? get errorMsg => _errorMsg;

  bool _isSuccess = false;
  bool get isSuccess => _isSuccess;

  List<UserEntity> _staffs = [];
  List<UserEntity> get staffs => _staffs;

  StaffStats? _stats;
  StaffStats? get stats => _stats;

  List<Map<String, dynamic>> _recentPatients = [];
  List<Map<String, dynamic>> get recentPatients => _recentPatients;

  Future<void> loadStaffs() async {
    _isLoading = true;
    _errorMsg = null;
    notifyListeners();

    try {
      _staffs = await _authRepo.getAllStaffs();
    } catch (e) {
      _errorMsg = 'Lỗi khi tải danh sách nhân sự: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createStaff({
    required String fullName,
    required String email,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMsg = null;
    _isSuccess = false;
    notifyListeners();

    try {
      final newUser = UserEntity(
        fullName: fullName,
        email: email,
        phone: phone,
        role: 'STAFF',
      );

      // System sets a default password for staff accounts
      const defaultPassword = '123456';

      await _authRepo.createStaffAccount(newUser, defaultPassword);
      _isSuccess = true;

      // Reload list after success
      await loadStaffs();
      return true;
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed: user_accounts.email')) {
        _errorMsg = 'Email đã được sử dụng.';
      } else {
        _errorMsg = 'Lỗi khi tạo nhân viên: ${e.toString()}';
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearState() {
    _errorMsg = null;
    _isSuccess = false;
    notifyListeners();
  }

  Future<bool> updateStaff(int userId, {String? fullName, String? email, String? phone, String? status}) async {
    _isLoading = true;
    _errorMsg = null;
    notifyListeners();

    try {
      final ok = await _authRepo.updateStaff(userId, fullName: fullName, email: email, phone: phone, status: status);
      if (ok) await loadStaffs();
      return ok;
    } catch (e) {
      if (e.toString().contains('UNIQUE')) {
        _errorMsg = 'Email đã được sử dụng.';
      } else {
        _errorMsg = 'Lỗi khi cập nhật nhân viên: ${e.toString()}';
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteStaff(int userId) async {
    _isLoading = true;
    _errorMsg = null;
    notifyListeners();

    try {
      final ok = await _authRepo.deleteStaff(userId);
      if (ok) await loadStaffs();
      return ok;
    } catch (e) {
      _errorMsg = 'Lỗi khi xoá nhân viên: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStats() async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now();
      final startOfToday =
          DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

      final todayDocs = await db.rawQuery(
          'SELECT COUNT(*) as count FROM medical_documents WHERE created_at >= ? AND is_deleted = 0',
          [startOfToday]);

      final totalDocs = await db.rawQuery(
          'SELECT COUNT(*) as count FROM medical_documents WHERE is_deleted = 0');

      _stats = StaffStats(
        documentToday: Sqflite.firstIntValue(todayDocs) ?? 0,
        totalDocuments: Sqflite.firstIntValue(totalDocs) ?? 0,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading staff stats: $e');
    }
  }

  Future<void> loadRecentDocuments() async {
    try {
      final db = await _dbHelper.database;
      // Get 5 most recent patients from patient_profiles
      final maps = await db.query(
        'patient_profiles',
        orderBy: 'created_at DESC',
        limit: 5,
      );
      _recentPatients = maps;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading recent patients: $e');
    }
  }
}
