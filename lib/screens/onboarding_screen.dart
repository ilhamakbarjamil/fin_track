import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fin_track/utils/theme.dart';
import 'package:fin_track/providers/transaction_provider.dart';
import 'package:fin_track/services/database_helper.dart';
import 'package:fin_track/screens/dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final cashController = TextEditingController();
  final bankNameController = TextEditingController();
  final bankBalanceController = TextEditingController();

  bool _isLoading = false;

  void _finishSetup() async {
    setState(() => _isLoading = true);

    // 1. Update Saldo Tunai (ID 1 adalah default Tunai di database)
    if (cashController.text.isNotEmpty) {
      int cashAmount = int.parse(cashController.text.replaceAll('.', ''));
      await DatabaseHelper.instance.setWalletBalance(1, cashAmount);
    }

    // 2. Tambah Bank Tambahan (Jika diisi)
    if (bankNameController.text.isNotEmpty && bankBalanceController.text.isNotEmpty) {
      int bankAmount = int.parse(bankBalanceController.text.replaceAll('.', ''));
      await DatabaseHelper.instance.addWallet(bankNameController.text, bankAmount);
    }

    // 3. Refresh Provider biar data masuk ke State
    if (mounted) {
      await Provider.of<TransactionProvider>(context, listen: false).loadData();
    }

    // 4. Tandai bahwa user sudah pernah setup (Save ke Shared Preferences)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_run', false);

    // 5. Pindah ke Dashboard
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Selamat Datang! 👋", style: whiteTextStyle.copyWith(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Sebelum mulai, mari catat posisi keuanganmu saat ini.", style: whiteTextStyle.copyWith(fontSize: 14)),
              
              const SizedBox(height: 40),
              
              // Input Tunai
              _buildInputLabel("Berapa uang tunai di dompetmu?"),
              _buildTextField(cashController, "0", true),
              
              const SizedBox(height: 24),
              
              // Input Bank
              _buildInputLabel("Punya rekening Bank / E-Wallet utama? (Opsional)"),
              Row(
                children: [
                  Expanded(flex: 2, child: _buildTextField(bankNameController, "Nama (Misal: BCA)", false)),
                  const SizedBox(width: 12),
                  Expanded(flex: 3, child: _buildTextField(bankBalanceController, "Saldo", true)),
                ],
              ),

              const Spacer(),

              // Tombol Mulai
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _finishSetup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator()
                    : Text("Mulai Mencatat 🚀", style: blackTextStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: whiteTextStyle.copyWith(fontSize: 12, color: Colors.white70)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, bool isNumber) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: blackTextStyle,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}