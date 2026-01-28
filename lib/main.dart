import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi format tanggal Indonesia
  await initializeDateFormatting('id_ID', null);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FinTrack',
      theme: ThemeData(
        // Kita set warna utama jadi Navy Blue (ala Bank)
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[100], // Background agak abu terang
        useMaterial3: true,
        // Set font default jadi Poppins/Roboto biar modern
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const Scaffold(
        body: Center(
          child: Text("Setup Project Berhasil!"),
        ),
      ),
    );
  }
}