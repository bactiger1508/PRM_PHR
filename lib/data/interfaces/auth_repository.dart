import '../../domain/entities/user_entity.dart';

abstract class AuthRepository {
  /// Authenticates a user based on email/password and role.
  /// If [isCustomer] is true, checks for CUSTOMER role.
  /// If [isCustomer] is false, checks for STAFF or ADMIN roles.
  Future<UserEntity?> login(String email, String password, bool isCustomer);

  /// Changes password for a given user ID
  Future<bool> changePassword(int userId, String newPassword);

  /// Creates a new staff or admin account.
  Future<int> createStaffAccount(UserEntity staffUser, String defaultPassword);

  /// Gets all staff and admin accounts.
  Future<List<UserEntity>> getAllStaffs();

  /// Creates a customer account for a patient.
  Future<int> createCustomerAccount(String email, String password, String? fullName);

  /// Find user by email
  Future<UserEntity?> findByEmail(String email);

  /// Save OTP code to database
  Future<void> saveOtp(String email, String otpCode, String purpose);

  /// Verify OTP code
  Future<bool> verifyOtp(String email, String otpCode, String purpose);

  /// Reset password using email (after OTP verified)
  Future<bool> resetPasswordByEmail(String email, String newPassword);
}
