import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'db_helper.dart';

class RecapScreen extends StatefulWidget {
  const RecapScreen({super.key});

  @override
  State<RecapScreen> createState() => _RecapScreenState();
}

class _RecapScreenState extends State<RecapScreen> {
  List<Map<String, dynamic>> _allTransactions = [];
  double totalIncome = 0;
  double totalExpense = 0;
  
  // List Kategori yang sudah diurutkan (Top Pengeluaran)
  List<Map<String, dynamic>> _topExpenses = [];

  bool isLoading = true;
  DateTime _selectedDate = DateTime.now();

  // Helper untuk warna kategori
  final Map<String, Color> categoryColors = {
    'Makanan': Colors.orange, 'Transport': Colors.blue, 'Belanja': Colors.pink,
    'Tagihan': Colors.red, 'Hiburan': Colors.purple, 'Kesehatan': Colors.teal,
    'Pendidikan': Colors.indigo, 'Lainnya': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      _loadRecapData();
    });
  }

  void _loadRecapData() async {
    final data = await DatabaseHelper.instance.getTransactions();
    if (mounted) {
      setState(() {
        _allTransactions = data;
        isLoading = false;
        _calculateForSelectedMonth();
      });
    }
  }

  void _calculateForSelectedMonth() {
    double income = 0;
    double expense = 0;
    Map<String, double> expenseGroup = {}; // Tampung total per kategori

    for (var item in _allTransactions) {
      DateTime txDate = DateTime.parse(item['date']);
      if (txDate.month == _selectedDate.month && txDate.year == _selectedDate.year) {
        if (item['type'] == 'IN') {
          income += item['amount'];
        } else {
          expense += item['amount'];
          // Kelompokkan Kategori Pengeluaran
          String cat = item['category'] ?? 'Lainnya';
          if (expenseGroup.containsKey(cat)) {
            expenseGroup[cat] = expenseGroup[cat]! + item['amount'];
          } else {
            expenseGroup[cat] = (item['amount'] as int).toDouble();
          }
        }
      }
    }

    // Urutkan Pengeluaran (Terbesar ke Terkecil)
    List<Map<String, dynamic>> sortedList = [];
    expenseGroup.forEach((key, value) {
      sortedList.add({'category': key, 'amount': value});
    });
    sortedList.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));

    setState(() {
      totalIncome = income;
      totalExpense = expense;
      _topExpenses = sortedList;
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + offset, 1);
      _calculateForSelectedMonth();
    });
  }

  String formatRupiah(double number) {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatCurrency.format(number);
  }

  @override
  Widget build(BuildContext context) {
    double totalFlow = totalIncome + totalExpense;
    String monthLabel = DateFormat('MMMM yyyy', 'id_ID').format(_selectedDate); 

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text("Rekap Bulanan", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: isLoading 
      ? const Center(child: CircularProgressIndicator())
      : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SELECTOR BULAN
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
                    Text(monthLabel, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
                  ],
                ),
              ),

              // CARD CASHFLOW (Pie Chart)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    Text("Pemasukan vs Pengeluaran", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 180,
                      child: totalFlow == 0 
                      ? Center(child: Text("Belum ada data", style: GoogleFonts.poppins(color: Colors.grey)))
                      : PieChart(
                        PieChartData(
                          sectionsSpace: 2, centerSpaceRadius: 40,
                          sections: [
                            PieChartSectionData(
                              color: Colors.green, value: totalIncome, title: "", radius: 50,
                            ),
                            PieChartSectionData(
                              color: Colors.redAccent, value: totalExpense, title: "", radius: 50,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _legendItem("Masuk", Colors.green, totalIncome),
                        const SizedBox(width: 20),
                        _legendItem("Keluar", Colors.redAccent, totalExpense),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // LIST TOP PENGELUARAN (KATEGORI)
              Text("Pengeluaran Terbesar", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              _topExpenses.isEmpty
              ? Container(
                  width: double.infinity, padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                  child: Center(child: Text("Belum ada pengeluaran", style: GoogleFonts.poppins(color: Colors.grey))),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _topExpenses.length,
                  itemBuilder: (context, index) {
                    final item = _topExpenses[index];
                    String catName = item['category'];
                    double amount = item['amount'];
                    double percent = totalExpense == 0 ? 0 : (amount / totalExpense);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: (categoryColors[catName] ?? Colors.grey).withOpacity(0.2),
                                    radius: 15,
                                    child: Icon(Icons.category, size: 15, color: categoryColors[catName] ?? Colors.grey),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(catName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                ],
                              ),
                              Text(formatRupiah(amount), style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Progress Bar
                          LinearProgressIndicator(
                            value: percent,
                            backgroundColor: Colors.grey[100],
                            color: categoryColors[catName] ?? Colors.grey,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text("${(percent * 100).toStringAsFixed(1)}%", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                          )
                        ],
                      ),
                    );
                  },
                ),
               
               const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color, double value) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
        const SizedBox(width: 5),
        Text(formatRupiah(value), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}