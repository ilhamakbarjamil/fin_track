import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'utils/theme.dart';
import 'providers/transaction_provider.dart'; // Import Provider Kita

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // BUNGKUS DENGAN MULTIPROVIDER
    return MultiProvider(
      providers: [
        // Daftarkan Provider disini
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FinTrack',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          scaffoldBackgroundColor: Colors.grey[100],
          useMaterial3: true,
          textTheme: GoogleFonts.poppinsTextTheme(
            Theme.of(context).textTheme,
          ),
        ),
        // Nanti kita ganti ini ke DashboardScreen
        home: const Scaffold(
           body: Center(child: Text("Logic Provider Siap!")),
        ),
      ),
    );
  }
}