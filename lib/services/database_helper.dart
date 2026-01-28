import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fintrack.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // 1. Tabel Wallets (Dompet)
    // id: Auto increment
    // name: Nama dompet (BCA, Tunai)
    // balance: Saldo saat ini (biar cepat load di HP jadul)
    // icon: Kode icon (integer)
    await db.execute('''
    CREATE TABLE wallets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      balance INTEGER NOT NULL DEFAULT 0,
      icon INTEGER
    )
    ''');

    // 2. Tabel Categories (Kategori)
    // type: 1 = Pemasukan, 2 = Pengeluaran
    await db.execute('''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      type INTEGER NOT NULL,
      icon INTEGER
    )
    ''');

    // 3. Tabel Transactions (Transaksi)
    // wallet_id: Link ke tabel wallets
    // category_id: Link ke tabel categories
    // created_at: Tanggal transaksi (Format ISO8601 String)
    await db.execute('''
    CREATE TABLE transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      wallet_id INTEGER NOT NULL,
      category_id INTEGER,
      amount INTEGER NOT NULL,
      description TEXT,
      date TEXT NOT NULL,
      type INTEGER NOT NULL,
      FOREIGN KEY (wallet_id) REFERENCES wallets (id),
      FOREIGN KEY (category_id) REFERENCES categories (id)
    )
    ''');

    // 4. Tabel Goals (Tabungan/Impian) - Sesuai requestmu
    await db.execute('''
    CREATE TABLE goals (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      target_amount INTEGER NOT NULL,
      current_amount INTEGER NOT NULL DEFAULT 0,
      wallet_id INTEGER, 
      is_achieved INTEGER DEFAULT 0
    )
    ''');

    // --- SEED DATA (Data Awal) ---
    // Masukkan data default biar aplikasi tidak kosong melompong saat install

    // Default Wallet
    await db.rawInsert(
      'INSERT INTO wallets(name, balance, icon) VALUES("Tunai", 0, 0)',
    );

    // Default Categories - Pengeluaran (Type 2)
    await db.rawInsert(
      'INSERT INTO categories(name, type, icon) VALUES("Makan & Minum", 2, 0)',
    );
    await db.rawInsert(
      'INSERT INTO categories(name, type, icon) VALUES("Transportasi", 2, 1)',
    );
    await db.rawInsert(
      'INSERT INTO categories(name, type, icon) VALUES("Belanja", 2, 2)',
    );
    await db.rawInsert(
      'INSERT INTO categories(name, type, icon) VALUES("Tagihan", 2, 3)',
    );

    // Default Categories - Pemasukan (Type 1)
    await db.rawInsert(
      'INSERT INTO categories(name, type, icon) VALUES("Gaji", 1, 4)',
    );
    await db.rawInsert(
      'INSERT INTO categories(name, type, icon) VALUES("Bonus", 1, 5)',
    );
  }

  // --- CRUD METHODS (Fungsi Dasar) ---

  // 1. Ambil Semua Data Dompet
  Future<List<Map<String, dynamic>>> getWallets() async {
    final db = await instance.database;
    return await db.query('wallets');
  }

  // 2. Ambil Semua Data Kategori
  Future<List<Map<String, dynamic>>> getCategories(int type) async {
    // type: 1 = Pemasukan, 2 = Pengeluaran
    final db = await instance.database;
    return await db.query('categories', where: 'type = ?', whereArgs: [type]);
  }

  // 3. Tambah Transaksi Baru (Dan Update Saldo Dompet)
  Future<int> addTransaction(Map<String, dynamic> row) async {
    final db = await instance.database;

    // a. Simpan Transaksi
    final id = await db.insert('transactions', row);

    // b. Update Saldo Dompet Otomatis
    int walletId = row['wallet_id'];
    int amount = row['amount'];
    int type = row['type']; // 1 = Masuk, 2 = Keluar

    // Logika: Kalau Pemasukan (1) saldo nambah, Kalau Pengeluaran (2) saldo kurang
    if (type == 1) {
      await db.rawUpdate(
        'UPDATE wallets SET balance = balance + ? WHERE id = ?',
        [amount, walletId],
      );
    } else {
      await db.rawUpdate(
        'UPDATE wallets SET balance = balance - ? WHERE id = ?',
        [amount, walletId],
      );
    }

    return id;
  }

  // 4. Ambil 5 Transaksi Terakhir (Untuk Dashboard)
  Future<List<Map<String, dynamic>>> getRecentTransactions() async {
    final db = await instance.database;
    // Join tabel biar kita dapat nama Kategori dan nama Wallet, bukan cuma ID-nya
    return await db.rawQuery('''
      SELECT t.*, c.name as category_name, c.icon as category_icon, w.name as wallet_name 
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      LEFT JOIN wallets w ON t.wallet_id = w.id
      ORDER BY t.date DESC
      LIMIT 5
    ''');
  }

  // --- FITUR GOALS / TABUNGAN ---

  // 5. Ambil Semua Data Goals
  Future<List<Map<String, dynamic>>> getGoals() async {
    final db = await instance.database;
    // Urutkan yang belum tercapai (is_achieved = 0) di atas
    return await db.query('goals', orderBy: 'is_achieved ASC, id DESC');
  }

  // 6. Tambah Goal Baru
  Future<int> addGoal(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('goals', row);
  }

  // 7. Top Up Tabungan (Nabung)
  Future<void> topUpGoal(int goalId, int amount, int walletId) async {
    final db = await instance.database;

    // A. Kurangi Saldo Dompet Sumber (Misal: BCA berkurang)
    await db.rawUpdate(
      'UPDATE wallets SET balance = balance - ? WHERE id = ?',
      [amount, walletId],
    );

    // B. Tambah Saldo di Goal (Tabungan bertambah)
    await db.rawUpdate(
      'UPDATE goals SET current_amount = current_amount + ? WHERE id = ?',
      [amount, goalId],
    );

    // C. Cek apakah sudah capai target?
    // (Opsional: Logic ini bisa ditaruh di Provider, tapi disini biar simple)
  }

  // --- FITUR ONBOARDING / SETUP ---

  // 8. Update Saldo Langsung (Untuk Setup Awal)
  Future<void> setWalletBalance(int id, int amount) async {
    final db = await instance.database;
    await db.rawUpdate('UPDATE wallets SET balance = ? WHERE id = ?', [
      amount,
      id,
    ]);
  }

  // 9. Tambah Dompet Baru (Misal user mau tambah BCA/OVO saat setup)
  Future<int> addWallet(String name, int balance) async {
    final db = await instance.database;
    return await db.insert('wallets', {
      'name': name,
      'balance': balance,
      'icon': 1, // Icon default bank
    });
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}