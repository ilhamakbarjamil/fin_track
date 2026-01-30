import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    // _database = await _initDB('my_finance.db');
    _database = await _initDB('sultan_finance_v2.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // 1. Tabel Aset (Update: ganti iconCode jadi logoSlug)
    await db.execute('''
      CREATE TABLE assets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        balance INTEGER NOT NULL,
        type TEXT NOT NULL,
        colorCode INTEGER NOT NULL,
        logoSlug TEXT NOT NULL -- Menyimpan kode logo (misal: 'bca', 'gopay')
      )
    ''');

    // 2. Tabel Goals
    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        targetAmount INTEGER NOT NULL,
        currentAmount INTEGER NOT NULL,
        colorCode INTEGER NOT NULL
      )
    ''');

    // 3. Tabel Transaksi
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount INTEGER NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        assetId INTEGER,
        category TEXT -- Kolom Baru
      )
    ''');

    // DATA AWAL
    await db.insert('assets', {
      'name': 'Cash (Dompet)',
      'balance': 0,
      'type': 'CASH',
      'colorCode': 0xFFFFA000,
      'logoSlug': 'cash' // Default
    });
  }

  // --- CRUD GOALS (EDIT & DELETE) ---

  // Update Data Goals (Nama, Target, Saldo Terkini)
  Future<int> updateGoal(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'goals',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Hapus Goals
  Future<int> deleteGoal(int id) async {
    final db = await instance.database;
    return await db.delete(
      'goals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- CRUD METHODS ---
  // --- TAMBAHAN UNTUK EDIT & HAPUS ASET ---

  // 1. Update Data Aset (Nama, Saldo, Logo)
  Future<int> updateAsset(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'assets',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 2. Hapus Aset
  Future<int> deleteAsset(int id) async {
    final db = await instance.database;
    return await db.delete(
      'assets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // A. FITUR ASET
  Future<List<Map<String, dynamic>>> getAssets() async {
    final db = await instance.database;
    return await db.query('assets');
  }

  Future<int> addAsset(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('assets', row);
  }

  Future<int> updateAssetBalance(int id, int newBalance) async {
    final db = await instance.database;
    return await db.update(
      'assets',
      {'balance': newBalance},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // B. FITUR GOALS
  Future<List<Map<String, dynamic>>> getGoals() async {
    final db = await instance.database;
    return await db.query('goals');
  }

  Future<int> addGoal(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('goals', row);
  }

  Future<int> updateGoalProgress(int id, int addAmount) async {
    // Logic: Ambil dulu current amount, lalu tambah
    final db = await instance.database;
    final result = await db.query('goals', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      int current = result.first['currentAmount'] as int;
      return await db.update(
        'goals',
        {'currentAmount': current + addAmount},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    return 0;
  }

  // C. FITUR TRANSAKSI (RIWAYAT)
  Future<int> addTransaction(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('transactions', row);
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    final db = await instance.database;
    return await db.query(
      'transactions',
      orderBy: 'date DESC',
    ); // Urutkan dari yang terbaru
  }

  // --- FITUR BAHAYA: RESET TOTAL ---
  Future<void> resetDatabase() async {
    final db = await instance.database;
    // Hapus semua data di tabel
    await db.delete('assets');
    await db.delete('goals');
    await db.delete('transactions');
    
    // Kembalikan data default (Cash)
    await db.insert('assets', {
      'name': 'Cash (Dompet)',
      'balance': 0,
      'type': 'CASH',
      'colorCode': 0xFF9E9E9E,
      'logoSlug': 'cash'
    });
  }
}
