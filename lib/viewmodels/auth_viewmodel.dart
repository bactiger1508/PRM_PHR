import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/exceptions/patient_profile_locked_exception.dart';
import '../data/implementations/auth_repository_impl.dart';
import '../data/interfaces/auth_repository.dart';
import '../domain/entities/user_entity.dart';

class AuthViewModel extends ChangeNotifier {
  static final AuthViewModel instance = AuthViewModel._internal();

  factory AuthViewModel() => instance;

  final AuthRepository _authRepo;

  AuthViewModel._internal({AuthRepository? authRepo})
    : _authRepo = authRepo ?? AuthRepositoryImpl();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMsg;
  String? get errorMsg => _errorMsg;

  UserEntity? _currentUser;
  UserEntity? get currentUser => _currentUser;

  Future<UserEntity?> login(
    String phoneOrEmail,
    String password,
    bool isCustomer,
    bool rememberMe,
  ) async {
    if (phoneOrEmail.isEmpty || password.isEmpty) {
      _errorMsg = 'Vui lòng nhập số điện thoại/email và mật khẩu.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMsg = null;
    notifyListeners();

    try {
      final user = await _authRepo.login(phoneOrEmail, password, isCustomer);
      if (user == null) {
        _errorMsg =
            'Thông tin đăng nhập không chính xác hoặc sai loại tài khoản.';
      } else {
        _currentUser = user;
        if (rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setBool('isCustomer', isCustomer);
          await prefs.setInt('userId', user.id!);
          await prefs.setString('userRole', user.role);
        }
      }
      return user;
    } on PatientProfileLockedException {
      _errorMsg =
          'Hồ sơ bệnh nhân của bạn đã bị khóa. Vui lòng liên hệ cơ sở y tế.';
      return null;
    } catch (e) {
      _errorMsg = 'Đã có lỗi xảy ra: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword(
    int userId,
    String newPassword,
    String confirmPassword,
  ) async {
    if (newPassword.length < 6) {
      _errorMsg = 'Mật khẩu phải từ 6 ký tự trở lên';
      notifyListeners();
      return false;
    }
    if (newPassword != confirmPassword) {
      _errorMsg = 'Mật khẩu xác nhận không khớp';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMsg = null;
    notifyListeners();

    try {
      final success = await _authRepo.changePassword(userId, newPassword);
      if (!success) {
        _errorMsg = 'Đổi mật khẩu thất bại. Vui lòng thử lại.';
      }
      return success;
    } catch (e) {
      _errorMsg = 'Lỗi: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('userId');
    await prefs.remove('userRole');
    await prefs.remove('isCustomer');
    notifyListeners();
  }

  void updateLocalAvatar(String newAvatarPath) {
    if (_currentUser != null) {
      _currentUser = UserEntity(
        id: _currentUser!.id,
        fullName: _currentUser!.fullName,
        phone: _currentUser!.phone,
        email: _currentUser!.email,
        role: _currentUser!.role,
        avatar: newAvatarPath,
        familyId: _currentUser!.familyId,
        isFamilyHead: _currentUser!.isFamilyHead,
      );
      notifyListeners();
    }
  }

  void refreshCurrentUser(UserEntity user) {
    _currentUser = user;
    notifyListeners();
  }
}
