import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class TransactionProvider with ChangeNotifier {
  // List penampung data untuk ditampilkan di UI
  List<Map<String, dynamic>> _wallets = [];
  List<Map<String, dynamic>> _recentTransactions = [];

  // Getter (supaya UI bisa ambil data)
  List<Map<String, dynamic>> get wallets => _wallets;
  List<Map<String, dynamic>> get recentTransactions => _recentTransactions;

  List<Map<String, dynamic>> _goals = [];
  List<Map<String, dynamic>> get goals => _goals;

  // Hitung Total Harta (Semua saldo dompet dijumlah)
  int get totalBalance {
    int total = 0;
    for (var wallet in _wallets) {
      total += (wallet['balance'] as int);
    }
    return total;
  }

  // --- ACTIONS ---

  // 1. Load Data Awal (Dipanggil saat aplikasi dibuka)
  Future<void> loadData() async {
    _wallets = await DatabaseHelper.instance.getWallets();
    _recentTransactions = await DatabaseHelper.instance.getRecentTransactions();
    _goals = await DatabaseHelper.instance.getGoals(); // <--- TAMBAHAN
    notifyListeners();
  }

  // 2. Tambah Transaksi
  Future<void> addTransaction({
    required int walletId,
    required int amount,
    required int type, // 1 = Masuk, 2 = Keluar
    int? categoryId,
    String? description,
    required DateTime date,
  }) async {
    Map<String, dynamic> row = {
      'wallet_id': walletId,
      'amount': amount,
      'type': type,
      'category_id': categoryId,
      'description': description,
      'date': date.toIso8601String(),
    };

    await DatabaseHelper.instance.addTransaction(row);

    // Refresh data setelah nambah biar saldo langsung update
    await loadData();
  }

  // 3. Tambah Goal Baru
  Future<void> addGoal(String name, int targetAmount) async {
    await DatabaseHelper.instance.addGoal({
      'name': name,
      'target_amount': targetAmount,
      'current_amount': 0,
      'is_achieved': 0,
    });
    await loadData(); // Refresh UI
  }

  // 4. Nabung (Top Up)
  Future<void> topUpGoal(int goalId, int amount, int walletId) async {
    await DatabaseHelper.instance.topUpGoal(goalId, amount, walletId);

    // Kita catat juga di riwayat transaksi biar ada jejaknya
    // "Nabung ke [Goal ID]" dianggap Pengeluaran dari Wallet
    await DatabaseHelper.instance.addTransaction({
      'wallet_id': walletId,
      'amount': amount,
      'type': 2, // Pengeluaran
      'category_id':
          null, // Kategori null atau bisa buat kategori khusus "Tabungan"
      'description': 'Tabungan Goal #$goalId',
      'date': DateTime.now().toIso8601String(),
    });

    await loadData();
  }
}