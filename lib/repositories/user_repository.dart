import '../db/app_db.dart';
import '../models/user_model.dart';

class UserRepository {
  final _dbFuture = AppDatabase.instance.database;

  Future<User?> login(String name, String password) async {
    final db = await _dbFuture;
    final result = await db.query(
      'users',
      where: 'name = ? AND password = ?',
      whereArgs: [name, password],
    );
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  Future<User?> getUserByUsername(String name) async {
    final db = await _dbFuture;
    final result = await db.query(
      'users',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  Future<bool> register(String name, String password) async {
    final db = await _dbFuture;
    final existing = await db.query(
      'users',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (existing.isNotEmpty) return false;

    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      password: password,
    );
    await db.insert('users', user.toMap());
    return true;
  }
}
