import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('restaurant.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
 await db.execute('''
  CREATE TABLE users (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL
  );
''');



    await db.execute('''
    CREATE TABLE restaurant_tables (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      isBooked INTEGER NOT NULL,
      bookedByUserId TEXT
    );
  ''');

    await db.execute('''
    CREATE TABLE menu_items (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      price REAL NOT NULL
    );
  ''');

    await db.execute('''
  CREATE TABLE orders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,  -- ✅ Required!
    userId TEXT NOT NULL,
    tableId INTEGER NOT NULL,
    timestamp TEXT NOT NULL,
    isCompleted INTEGER NOT NULL
  );
''');


    await db.execute('''
    CREATE TABLE order_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      orderId INTEGER NOT NULL,
      menuItemId INTEGER NOT NULL,
      quantity INTEGER NOT NULL
    );
  ''');

    // ✅ Seed tables
    for (int i = 1; i <= 10; i++) {
      await db.insert('restaurant_tables', {
        'id': i,
        'name': 'Table $i',
        'isBooked': 0,
        'bookedByUserId': null,
      });
    }

    // ✅ Seed menu items
    List<Map<String, dynamic>> menuItems = [
      {'id': 1, 'name': 'Pizza', 'price': 199.0},
      {'id': 2, 'name': 'Burger', 'price': 99.0},
      {'id': 3, 'name': 'Pasta', 'price': 149.0},
      {'id': 4, 'name': 'Coke', 'price': 49.0},
    ];

    for (var item in menuItems) {
      await db.insert('menu_items', item);
    }
    
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
