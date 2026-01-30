import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'db_helper.dart';
import 'notification_helper.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER PROFILE (GRADIENT)
            Container(
              padding: const EdgeInsets.only(top: 60, bottom: 30),
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF003973), Color(0xFF0052D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/300?img=12',
                    ), // Dummy Photo
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Sultan Finance",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Member sejak 2024",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // MENU PENGATURAN
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildMenuCard(
                    context,
                    Icons.person_outline,
                    "Edit Profil",
                    "Ubah nama & foto",
                    () {},
                  ),
                  _buildMenuCard(
                    context,
                    Icons.notifications_outlined,
                    "Tes Notifikasi",
                    "Klik untuk cek notifikasi",
                    () async {
                      // 1. Minta Izin dulu (jika belum)
                      await NotificationHelper.requestPermission();
                      // 2. Tampilkan Notifikasi Langsung
                      await NotificationHelper.showTestNotification();
                    },
                  ),
                  _buildMenuCard(
                    context,
                    Icons.security,
                    "Keamanan",
                    "Fingerprint & PIN",
                    () {},
                  ),
                  _buildMenuCard(
                    context,
                    Icons.help_outline,
                    "Bantuan",
                    "Pusat bantuan & FAQ",
                    () {},
                  ),

                  const SizedBox(height: 20),

                  // TOMBOL BAHAYA (RESET DATA)
                  _buildMenuCard(
                    context,
                    Icons.delete_forever,
                    "Reset Data",
                    "Hapus semua data transaksi",
                    () {
                      _showResetConfirm(context);
                    },
                    isDanger: true,
                  ),
                ],
              ),
            ),

            Text(
              "Versi Aplikasi v1.0.0",
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDanger = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
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
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDanger
                ? Colors.red.withOpacity(0.1)
                : Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: isDanger ? Colors.red : Colors.blue),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: isDanger ? Colors.red : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showResetConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Semua Data?"),
        content: const Text(
          "Tindakan ini tidak bisa dibatalkan. Semua saldo, riwayat, dan goals akan hilang.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DatabaseHelper.instance.resetDatabase();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Data berhasil di-reset! Silakan restart aplikasi.",
                  ),
                ),
              );
            },
            child: const Text(
              "Hapus Semua",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
