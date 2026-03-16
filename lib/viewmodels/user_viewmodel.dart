import 'package:flutter/material.dart';
import 'package:phrprmgroupproject/data/implementations/user_repository_impl.dart';
import 'package:phrprmgroupproject/data/interfaces/user_repository.dart';

class UserViewModel extends ChangeNotifier {
  final UserRepository _userRepository = UserRepositoryImpl();

  final bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> changeAvatar(int userId, String? path) async {
    await _userRepository.updateAvatar(userId, path);
    notifyListeners();
  }
}