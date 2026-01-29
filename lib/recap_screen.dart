import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';

class RecapScreen extends StatefulWidget {
  const RecapScreen({super.key});

  @override
  State<RecapScreen> createState() => _RecapScreenState();
}

class _RecapScreenState extends State<RecapScreen> {
  double totalIncome = 0;
  double totalExpense = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecapData();
  }

  // Logic Hitung Data
  void _loadRecapData() async {
    final transactions = await DatabaseHelper.instance.getTransactions();
    
    double income = 0;
    double expense = 0;

    // Filter data (Bisa dikembangkan jadi filter per bulan nanti)
    for (var item in transactions) {
      if (item['type'] == 'IN') {
        income += item['amount'];
      } else {
        expense += item['amount'];
      }
    }

    if (mounted) {
      setState(() {
        totalIncome = income;
        totalExpense = expense;
        isLoading = false;
      });
    }
  }

  String formatRupiah(double number) {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatCurrency.format(number);
  }

  @override
  Widget build(BuildContext context) {
    double totalFlow = totalIncome + totalExpense;
    // Hindari pembagian dengan nol
    double incomePercent = totalFlow == 0 ? 0 : (totalIncome / totalFlow) * 100;
    double expensePercent = totalFlow == 0 ? 0 : (totalExpense / totalFlow) * 100;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text("Rekap Keuangan", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading 
      ? const Center(child: CircularProgressIndicator())
      : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 1. CARD DIAGRAM
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    Text("Cashflow Bulan Ini", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 20),
                    
                    // PIE CHART
                    SizedBox(
                      height: 200,
                      child: totalFlow == 0 
                      ? Center(child: Text("Belum ada data", style: GoogleFonts.poppins(color: Colors.grey)))
                      : PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 50,
                          sections: [
                            // Section Pemasukan (Hijau)
                            PieChartSectionData(
                              color: Colors.green,
                              value: totalIncome,
                              title: "${incomePercent.toStringAsFixed(0)}%",
                              radius: 60,
                              titleStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            // Section Pengeluaran (Merah)
                            PieChartSectionData(
                              color: Colors.redAccent,
                              value: totalExpense,
                              title: "${expensePercent.toStringAsFixed(0)}%",
                              radius: 60,
                              titleStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. DETAIL ANGKA
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard("Pemasukan", totalIncome, Colors.green, Icons.arrow_downward),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildInfoCard("Pengeluaran", totalExpense, Colors.redAccent, Icons.arrow_upward),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 3. CARD NETT (SELISIH)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF003973), Color(0xFF0052D4)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Sisa Uang (Nett)", style: GoogleFonts.poppins(color: Colors.white70)),
                    const SizedBox(height: 5),
                    Text(
                      formatRupiah(totalIncome - totalExpense),
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      (totalIncome - totalExpense) >= 0 
                      ? "Keuanganmu aman! Pertahankan." 
                      : "Waduh! Pengeluaran lebih besar dari pemasukan.",
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, double value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
        border: Border(left: BorderSide(color: color, width: 4))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 5),
              Text(title, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            formatRupiah(value),
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}