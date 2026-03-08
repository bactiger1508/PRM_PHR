import 'package:flutter/material.dart';
import '../data/interfaces/auth_repository.dart';
import '../data/implementations/auth_repository_impl.dart';
import '../domain/entities/user_entity.dart';

class StaffManagementViewModel extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepositoryImpl();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMsg;
  String? get errorMsg => _errorMsg;

  bool _isSuccess = false;
  bool get isSuccess => _isSuccess;

  List<UserEntity> _staffs = [];
  List<UserEntity> get staffs => _staffs;

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
}
