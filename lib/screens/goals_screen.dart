import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fin_track/utils/theme.dart';
import 'package:fin_track/utils/currency_format.dart';
import 'package:fin_track/providers/transaction_provider.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  // Dialog untuk Tambah Goal Baru
  void _showAddGoalDialog() {
    final nameController = TextEditingController();
    final targetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Target Tabungan Baru"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nama (Misal: Laptop)"),
            ),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Target Dana (Rp)"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && targetController.text.isNotEmpty) {
                Provider.of<TransactionProvider>(context, listen: false).addGoal(
                  nameController.text,
                  int.parse(targetController.text),
                );
                Navigator.pop(context);
              }
            },
            child: const Text("Simpan"),
          )
        ],
      ),
    );
  }

  // Dialog untuk Nabung (Top Up)
  void _showTopUpDialog(Map<String, dynamic> goal) {
    final amountController = TextEditingController();
    int? selectedWalletId;
    final wallets = Provider.of<TransactionProvider>(context, listen: false).wallets;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( // StatefulBuilder biar dropdown bisa berubah
        builder: (context, setState) {
          return AlertDialog(
            title: Text("Nabung: ${goal['name']}"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Jumlah Nabung (Rp)"),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedWalletId,
                  hint: const Text("Ambil dari Dompet?"),
                  items: wallets.map((w) => DropdownMenuItem<int>(
                    value: w['id'],
                    child: Text("${w['name']} (Sisa: ${CurrencyFormat.convertToIdr(w['balance'], 0)})"),
                  )).toList(),
                  onChanged: (val) => setState(() => selectedWalletId = val),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
              ElevatedButton(
                onPressed: () {
                  if (amountController.text.isNotEmpty && selectedWalletId != null) {
                    Provider.of<TransactionProvider>(context, listen: false).topUpGoal(
                      goal['id'],
                      int.parse(amountController.text),
                      selectedWalletId!,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil menabung!")));
                  }
                },
                child: const Text("Nabung Sekarang"),
              )
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Impian / Tabungan"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalDialog,
        backgroundColor: kPrimaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          if (provider.goals.isEmpty) {
            return const Center(child: Text("Belum ada target tabungan."));
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.goals.length,
            itemBuilder: (context, index) {
              final goal = provider.goals[index];
              final double progress = (goal['current_amount'] / goal['target_amount']).clamp(0.0, 1.0);
              final int percent = (progress * 100).toInt();

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(goal['name'], style: blackTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text("$percent%", style: blueTextStyle.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // PROGRESS BAR
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        color: progress >= 1.0 ? Colors.green : kPrimaryColor,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${CurrencyFormat.convertToIdr(goal['current_amount'], 0)} / ${CurrencyFormat.convertToIdr(goal['target_amount'], 0)}",
                            style: greyTextStyle.copyWith(fontSize: 12),
                          ),
                          ElevatedButton(
                            onPressed: () => _showTopUpDialog(goal),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              minimumSize: Size.zero,
                            ),
                            child: const Text("Top Up", style: TextStyle(color: Colors.white, fontSize: 12)),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}