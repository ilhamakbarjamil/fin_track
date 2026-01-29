import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'db_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  
  // Format Tanggal
  String formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // Format Rupiah
  String formatRupiah(int number) {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatCurrency.format(number);
  }

  // --- FUNGSI EXPORT EXCEL ---
  Future<void> _exportToExcel() async {
    // 1. Ambil data dari Database
    final transactions = await DatabaseHelper.instance.getTransactions();
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tidak ada data untuk diekspor")));
      return;
    }

    // 2. Buat File Excel
    var excel = Excel.createExcel();
    // Rename Sheet default
    Sheet sheetObject = excel['Laporan Keuangan'];
    excel.setDefaultSheet('Laporan Keuangan');

    // 3. Buat Header Kolom
    // Styling cell header (Opsional, library excel flutter agak terbatas stylingnya, kita pakai basic)
    sheetObject.appendRow([
      TextCellValue('ID'), 
      TextCellValue('Tanggal'), 
      TextCellValue('Keterangan'), 
      TextCellValue('Tipe'), 
      TextCellValue('Nominal')
    ]);

    // 4. Isi Data Baris per Baris
    for (var item in transactions) {
      sheetObject.appendRow([
        IntCellValue(item['id']),
        TextCellValue(formatDate(item['date'])),
        TextCellValue(item['title']),
        TextCellValue(item['type'] == 'IN' ? 'Pemasukan' : 'Pengeluaran'),
        IntCellValue(item['amount']),
      ]);
    }

    // 5. Simpan File ke Temporary Directory
    var fileBytes = excel.save();
    var directory = await getTemporaryDirectory();
    
    // Nama file unik pakai timestamp
    String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    String fileName = "Laporan_Keuangan_$timestamp.xlsx";
    File file = File('${directory.path}/$fileName');
    
    await file.create(recursive: true);
    await file.writeAsBytes(fileBytes!);

    // 6. Share File (Agar user bisa pilih mau kirim ke WA/Email/Save to Files)
    // Menggunakan XFile dari share_plus
    await Share.shareXFiles([XFile(file.path)], text: 'Berikut Laporan Keuangan Saya');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Riwayat Transaksi",
          style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        // TOMBOL EXPORT DI POJOK KANAN ATAS
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Color(0xFF0052D4)),
            tooltip: 'Export Excel',
            onPressed: () {
              _exportToExcel();
            },
          )
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper.instance.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text("Belum ada transaksi", style: GoogleFonts.poppins(color: Colors.grey)),
                ],
              ),
            );
          }

          final transactions = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final item = transactions[index];
              final isIncome = item['type'] == 'IN';

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isIncome ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isIncome ? Colors.green : Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'],
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            formatDate(item['date']),
                            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "${isIncome ? '+' : '-'} ${formatRupiah(item['amount'])}",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: isIncome ? Colors.green : Colors.red,
                        fontSize: 14
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}