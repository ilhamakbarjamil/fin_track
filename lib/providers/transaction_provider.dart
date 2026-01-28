import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class TransactionProvider with ChangeNotifier {
  // List penampung data untuk ditampilkan di UI
  List<Map<String, dynamic>> _wallets = [];
  List<Map<String, dynamic>> _recentTransactions = [];
  
  // Getter (supaya UI bisa ambil data)
  List<Map<String, dynamic>> get wallets => _wallets;
  List<Map<String, dynamic>> get recentTransactions => _recentTransactions;

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
    
    // Memberitahu UI bahwa data sudah berubah (Refresh otomatis)
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
}