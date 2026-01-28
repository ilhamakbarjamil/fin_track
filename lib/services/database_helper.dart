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

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
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
    await db.rawInsert('INSERT INTO wallets(name, balance, icon) VALUES("Tunai", 0, 0)');
    
    // Default Categories - Pengeluaran (Type 2)
    await db.rawInsert('INSERT INTO categories(name, type, icon) VALUES("Makan & Minum", 2, 0)');
    await db.rawInsert('INSERT INTO categories(name, type, icon) VALUES("Transportasi", 2, 1)');
    await db.rawInsert('INSERT INTO categories(name, type, icon) VALUES("Belanja", 2, 2)');
    await db.rawInsert('INSERT INTO categories(name, type, icon) VALUES("Tagihan", 2, 3)');
    
    // Default Categories - Pemasukan (Type 1)
    await db.rawInsert('INSERT INTO categories(name, type, icon) VALUES("Gaji", 1, 4)');
    await db.rawInsert('INSERT INTO categories(name, type, icon) VALUES("Bonus", 1, 5)');
  }

  // --- CRUD METHODS (Fungsi Dasar) ---
  // Nanti kita isi fungsi Tambah/Hapus di sini saat masuk tahap Logic
  
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}