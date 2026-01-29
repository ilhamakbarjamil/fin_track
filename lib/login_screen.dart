import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'main.dart'; // Import main agar bisa pindah ke Dashboard

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  
  // Fungsi Cek & Eksekusi Fingerprint
  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      // Cek apakah HP support biometrik
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        // Jika HP jadul/emulator tanpa fitur fingerprint, langsung masuk (Bypass untuk testing)
        _navigateToDashboard();
        return;
      }

      // Tampilkan Dialog Fingerprint
      authenticated = await auth.authenticate(
        localizedReason: 'Scan sidik jari untuk masuk',
        options: const AuthenticationOptions(
          stickyAuth: true, // Agar dialog tidak hilang jika aplikasi ke-pause
          biometricOnly: false, // Boleh pakai PIN/Pola HP jika jari basah
        ),
      );
    } on PlatformException catch (e) {
      print(e);
      // Jika error, tampilkan pesan
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error Biometrik: ${e.message}"))
      );
      return;
    }

    // Jika Berhasil
    if (authenticated) {
      _navigateToDashboard();
    }
  }

  void _navigateToDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF003973), Color(0xFF0052D4)], // Biru Corporate
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo / Icon Aplikasi
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_wallet, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              "Sultan Finance",
              style: GoogleFonts.poppins(
                fontSize: 28, 
                fontWeight: FontWeight.bold, 
                color: Colors.white
              ),
            ),
            Text(
              "Kelola asetmu dengan elegan",
              style: GoogleFonts.poppins(
                fontSize: 14, 
                color: Colors.white70
              ),
            ),
            const SizedBox(height: 60),

            // Tombol Login
            ElevatedButton.icon(
              onPressed: _authenticate,
              icon: const Icon(Icons.fingerprint, size: 30),
              label: Text("Masuk dengan Fingerprint", style: GoogleFonts.poppins(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0052D4), // Warna Teks Biru
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 5,
              ),
            ),
            
            const SizedBox(height: 20),
            // Opsional: Tombol Login PIN (Dummy)
            TextButton(
              onPressed: () {
                // Logic login PIN (opsional, sementara bypass)
                 _navigateToDashboard();
              },
              child: Text("Gunakan PIN", style: GoogleFonts.poppins(color: Colors.white70)),
            )
          ],
        ),
      ),
    );
  }
}