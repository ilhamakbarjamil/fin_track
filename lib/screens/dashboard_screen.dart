import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fin_track/utils/theme.dart';
import 'package:fin_track/utils/currency_format.dart';
import 'package:fin_track/providers/transaction_provider.dart';
import 'package:fin_track/screens/add_transaction_screen.dart';
import 'package:fin_track/screens/transaction_detail_screen.dart';
import 'package:fin_track/screens/goals_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Panggil data saat halaman pertama kali dibuka
    Future.microtask(
      () => Provider.of<TransactionProvider>(context, listen: false).loadData(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      // Tombol Tambah Transaksi Melayang
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // NAVIGASI KE HALAMAN INPUT
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
        },
        backgroundColor: kPrimaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.home, color: kPrimaryColor),
                onPressed: () {}, // Sudah di Home
              ),
              const SizedBox(width: 40), // Spacer buat tombol tengah (+)
              IconButton(
                icon: const Icon(Icons.savings, color: Colors.grey),
                onPressed: () {
                  // PINDAH KE HALAMAN GOALS
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GoalsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Consumer<TransactionProvider>(
          builder: (context, provider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. HEADER & TOTAL SALDO (Kartu Biru)
                  _buildTotalBalanceCard(provider),

                  const SizedBox(height: 24),

                  // 2. LIST DOMPET (Horizontal Scroll)
                  Text(
                    "Dompet Saya",
                    style: blackTextStyle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildWalletList(provider),

                  const SizedBox(height: 24),

                  // 3. RIWAYAT TRANSAKSI
                  Text(
                    "Riwayat Terakhir",
                    style: blackTextStyle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRecentTransactions(provider),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // WIDGET: KARTU TOTAL SALDO
  Widget _buildTotalBalanceCard(TransactionProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kPrimaryColor, // Warna Navy Blue
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Total Kekayaan", style: whiteTextStyle.copyWith(fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            CurrencyFormat.convertToIdr(provider.totalBalance, 0),
            style: whiteTextStyle.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.arrow_circle_up, color: Colors.greenAccent),
              const SizedBox(width: 5),
              Text("Pemasukan", style: whiteTextStyle.copyWith(fontSize: 12)),
              const Spacer(),
              Text("Pengeluaran", style: whiteTextStyle.copyWith(fontSize: 12)),
              const SizedBox(width: 5),
              Icon(Icons.arrow_circle_down, color: Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  // WIDGET: LIST DOMPET HORIZONTAL
  Widget _buildWalletList(TransactionProvider provider) {
    if (provider.wallets.isEmpty) {
      return const Text("Belum ada dompet.");
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: provider.wallets.length,
        itemBuilder: (context, index) {
          final item = provider.recentTransactions[index];
          final isExpense = item['type'] == 2;

          // BUNGKUS DENGAN INKWELL AGAR BISA DIKLIK
          return InkWell(
            onTap: () {
              // Navigasi ke Halaman Detail
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      TransactionDetailScreen(transaction: item),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                // ... (Isi Row sama persis kayak sebelumnya, jangan diubah isinya) ...
                children: [
                  // Icon Kategori
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isExpense
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isExpense ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Detail
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['category_name'] ?? 'Umum',
                          style: blackTextStyle.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          item['wallet_name'] ?? '-',
                          style: greyTextStyle.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // Nominal
                  Text(
                    (isExpense ? "- " : "+ ") +
                        CurrencyFormat.convertToIdr(item['amount'], 0),
                    style: blackTextStyle.copyWith(
                      color: isExpense ? kExpenseColor : kIncomeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // WIDGET: LIST TRANSAKSI
  Widget _buildRecentTransactions(TransactionProvider provider) {
    if (provider.recentTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Text("Belum ada transaksi", style: greyTextStyle),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(), // Biar bisa scroll bareng parent
      itemCount: provider.recentTransactions.length,
      itemBuilder: (context, index) {
        final item = provider.recentTransactions[index];
        final isExpense = item['type'] == 2; // 2 = Pengeluaran

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Icon Kategori
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isExpense ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isExpense ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              // Detail
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['category_name'] ?? 'Umum',
                      style: blackTextStyle.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      item['wallet_name'] ?? '-',
                      style: greyTextStyle.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Nominal
              Text(
                (isExpense ? "- " : "+ ") +
                    CurrencyFormat.convertToIdr(item['amount'], 0),
                style: blackTextStyle.copyWith(
                  color: isExpense ? kExpenseColor : kIncomeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
