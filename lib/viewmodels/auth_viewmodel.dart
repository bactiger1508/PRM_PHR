import 'package:flutter/foundation.dart';
import '../data/implementations/auth_repository_impl.dart';
import '../data/interfaces/auth_repository.dart';
import '../domain/entities/user_entity.dart';

class AuthViewModel extends ChangeNotifier {
  static final AuthViewModel instance = AuthViewModel();

  final AuthRepository _authRepo;

  AuthViewModel({AuthRepository? authRepo})
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
      }
      return user;
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
}
