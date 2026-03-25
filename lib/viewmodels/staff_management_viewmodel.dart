import 'package:flutter/material.dart';
import 'package:phrprmgroupproject/data/db/database_helper.dart';
import 'package:phrprmgroupproject/data/implementations/audit_log_repository.dart';
import 'package:phrprmgroupproject/data/implementations/patient_repository_impl.dart';
import 'package:phrprmgroupproject/data/interfaces/patient_repository.dart';
import '../domain/entities/audit_log_entity.dart';
import '../domain/entities/patient_entity.dart';
import '../core/utils/string_utils.dart';
import '../data/interfaces/auth_repository.dart';
import '../data/implementations/auth_repository_impl.dart';
import '../domain/entities/user_entity.dart';
import 'auth_viewmodel.dart';

class StaffManagementViewModel extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepositoryImpl();
  final PatientRepository _patientRepository = PatientRepositoryImpl();
  final AuditLogRepository _auditRepo = AuditLogRepository();

  int? get _actorId => AuthViewModel.instance.currentUser?.id;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMsg;
  String? get errorMsg => _errorMsg;

  bool _isSuccess = false;
  bool get isSuccess => _isSuccess;

  List<UserEntity> _users = [];
  List<UserEntity> get users => _users;

  DashboardStats? _stats;
  DashboardStats? get stats => _stats;

  List<PatientEntity> _patients = [];
  List<PatientEntity> get patients => _patients;
  List<Map<String, dynamic>> _recentPatients = [];
  List<Map<String, dynamic>> get recentPatients => _recentPatients;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  List<PatientEntity> get filteredPatients {
    if (_searchQuery.isEmpty) return _patients;
    final normalizedQuery = StringUtils.removeDiacritics(_searchQuery.toLowerCase());
    return _patients.where((p) {
      final nameNormalized = StringUtils.removeDiacritics(p.fullName.toLowerCase());
      final codeNormalized = StringUtils.removeDiacritics(p.medicalCode.toLowerCase());
      final phoneNormalized = p.phone != null ? StringUtils.removeDiacritics(p.phone!.toLowerCase()) : '';
      
      return nameNormalized.contains(normalizedQuery) || 
             codeNormalized.contains(normalizedQuery) || 
             phoneNormalized.contains(normalizedQuery);
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadUsers() async {
    _isLoading = true;
    _errorMsg = null;
    notifyListeners();

    try {
      _users = await _authRepo.getAllUsers();
    } catch (e) {
      _errorMsg = 'Lỗi khi tải danh sách người dùng: ${e.toString()}';
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

      final newId = await _authRepo.createStaffAccount(newUser, defaultPassword);
      _isSuccess = true;

      await _auditRepo.saveLog(AuditLogEntity(
        userId: _actorId,
        action: 'Tạo tài khoản người dùng (nhân viên)',
        entityType: 'user_accounts',
        entityId: newId,
        details: 'Email: $email, họ tên: $fullName',
        timestamp: DateTime.now(),
      ));

      // Reload list after success
      await loadUsers();
      return true;
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed: user_accounts.email')) {
        _errorMsg = 'Email đã được sử dụng.';
      } else {
        _errorMsg = 'Lỗi khi tạo tài khoản nhân viên: ${e.toString()}';
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
      if (ok) {
        await _auditRepo.saveLog(AuditLogEntity(
          userId: _actorId,
          action: 'Cập nhật tài khoản người dùng',
          entityType: 'user_accounts',
          entityId: userId,
          details: 'Cập nhật thông tin người dùng ID $userId',
          timestamp: DateTime.now(),
        ));
        await loadUsers();
      }
      return ok;
    } catch (e) {
      if (e.toString().contains('UNIQUE')) {
        _errorMsg = 'Email đã được sử dụng.';
      } else {
        _errorMsg = 'Lỗi khi cập nhật người dùng: ${e.toString()}';
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
      if (ok) {
        await _auditRepo.saveLog(AuditLogEntity(
          userId: _actorId,
          action: 'Xóa tài khoản người dùng',
          entityType: 'user_accounts',
          entityId: userId,
          details: 'Đã xóa người dùng ID $userId',
          timestamp: DateTime.now(),
        ));
        await loadUsers();
      }
      return ok;
    } catch (e) {
      _errorMsg = 'Lỗi khi xoá người dùng: ${e.toString()}';
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
      debugPrint('Lỗi tải thống kê: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> loadPatients() async {
    _isLoading = true;
    notifyListeners();

    try {
      _patients = await _patientRepository.getAllPatients();
    } catch (e) {
      _errorMsg = 'Không thể tải danh sách bệnh nhân';
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
    } catch (e) {
      // Ignored
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
