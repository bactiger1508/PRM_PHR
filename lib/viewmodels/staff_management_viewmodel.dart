import 'package:flutter/material.dart';
import 'package:phrprmgroupproject/data/db/database_helper.dart';
import 'package:phrprmgroupproject/data/implementations/patient_repository_impl.dart';
import 'package:phrprmgroupproject/data/interfaces/patient_repository.dart';
import '../data/interfaces/auth_repository.dart';
import '../data/implementations/auth_repository_impl.dart';
import '../domain/entities/user_entity.dart';

class StaffManagementViewModel extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepositoryImpl();
  final PatientRepository _patientRepository = PatientRepositoryImpl();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMsg;
  String? get errorMsg => _errorMsg;

  bool _isSuccess = false;
  bool get isSuccess => _isSuccess;

  List<UserEntity> _staffs = [];
  List<UserEntity> get staffs => _staffs;

  DashboardStats? _stats;
  DashboardStats? get stats => _stats;

  List<UserEntity> _customers = [];
  List<UserEntity> get customers => _customers;
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
    _isLoading = true;
    notifyListeners();

    try {
      _stats = await _patientRepository.getStats();
    } catch (e) {
      print('Lỗi tải thống kê: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> loadPatients() async {
    _isLoading = true;
    notifyListeners();

    try {
      _customers = await _patientRepository.getAllCustomers();
      print('customer: ${_customers}');
    } catch (e) {
      print('Lỗi tải danh sách khách hàng: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRecentDocuments() async {
    _isLoading = true;
    notifyListeners();

    try {
      _recentPatients = await _patientRepository.getRecentPatients(limit: 3);
      print('Hồ sơ gần đây ${_recentPatients}');
    } catch (e) {
      print('Lỗi tải dữ liệu tài liệu: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
