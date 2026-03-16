abstract class UserRepository {
  Future<void> updateAvatar(int userId, String? avatarPath);
}