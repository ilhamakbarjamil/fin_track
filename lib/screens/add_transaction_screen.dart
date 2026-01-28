import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fin_track/utils/theme.dart';
import 'package:fin_track/providers/transaction_provider.dart';
import 'package:fin_track/services/database_helper.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  // Controller untuk input
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  
  // State (Status data yang sedang dipilih)
  int _type = 2; // Default 2 = Pengeluaran
  DateTime _selectedDate = DateTime.now();
  int? _selectedWalletId;
  int? _selectedCategoryId;
  
  // List data untuk Dropdown
  List<Map<String, dynamic>> _categories = [];
  
  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // Load kategori sesuai tipe (Masuk/Keluar)
  void _loadCategories() async {
    final data = await DatabaseHelper.instance.getCategories(_type);
    setState(() {
      _categories = data;
      // Reset pilihan kategori kalau tipe berubah
      _selectedCategoryId = null; 
    });
  }

  // Fungsi Simpan
  void _saveTransaction() async {
    if (amountController.text.isEmpty || _selectedWalletId == null || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mohon lengkapi data (Nominal, Dompet, Kategori)")),
      );
      return;
    }

    // Panggil Provider untuk simpan ke Database
    await Provider.of<TransactionProvider>(context, listen: false).addTransaction(
      walletId: _selectedWalletId!,
      amount: int.parse(amountController.text.replaceAll('.', '')), // Hapus titik format
      type: _type,
      categoryId: _selectedCategoryId,
      description: descController.text,
      date: _selectedDate,
    );

    // Kembali ke Dashboard
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Transaksi Berhasil Disimpan!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data wallets dari Provider yang sudah ada
    final wallets = Provider.of<TransactionProvider>(context).wallets;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Catat Transaksi"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TOGGLE TIPE (Pemasukan / Pengeluaran)
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _type = 2; // Pengeluaran
                        _loadCategories();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _type == 2 ? kExpenseColor : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          "Pengeluaran",
                          style: _type == 2 ? whiteTextStyle : greyTextStyle,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _type = 1; // Pemasukan
                        _loadCategories();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _type == 1 ? kIncomeColor : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          "Pemasukan",
                          style: _type == 1 ? whiteTextStyle : greyTextStyle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),

            // 2. INPUT NOMINAL (Besar)
            Text("Nominal", style: blackTextStyle.copyWith(fontSize: 14)),
            const SizedBox(height: 8),
            TextFormField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: blackTextStyle.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: "Rp ",
                hintText: "0",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 20),

            // 3. PILIH DOMPET (Sumber Dana)
            Text("Pilih Dompet / Akun", style: blackTextStyle.copyWith(fontSize: 14)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedWalletId,
              items: wallets.map((wallet) {
                return DropdownMenuItem<int>(
                  value: wallet['id'],
                  child: Text("${wallet['name']} (Sisa: ${wallet['balance']})"),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedWalletId = value;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              hint: const Text("Pilih Dompet"),
            ),

            const SizedBox(height: 20),

            // 4. PILIH KATEGORI
            Text("Kategori", style: blackTextStyle.copyWith(fontSize: 14)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedCategoryId,
              items: _categories.map((cat) {
                return DropdownMenuItem<int>(
                  value: cat['id'],
                  child: Text(cat['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              hint: const Text("Pilih Kategori"),
            ),

            const SizedBox(height: 20),

            // 5. TANGGAL
            Text("Tanggal Transaksi", style: blackTextStyle.copyWith(fontSize: 14)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (pickedDate != null) {
                  setState(() {
                    _selectedDate = pickedDate;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 10),
                    Text(DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // 6. TOMBOL SIMPAN
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("Simpan Transaksi", style: whiteTextStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}