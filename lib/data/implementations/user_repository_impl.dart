import 'package:phrprmgroupproject/data/db/database_helper.dart';
import 'package:phrprmgroupproject/data/interfaces/user_repository.dart';

class UserRepositoryImpl implements UserRepository{
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<void> updateAvatar(int userId, String? avatarPath) async {
    final db = await _dbHelper.database;

    await db.update(
      'user_accounts',
      {
        'avatar': avatarPath,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}