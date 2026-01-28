import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/theme.dart';
import 'providers/transaction_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart'; // Import layar baru

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
        // GUNAKAN SPLASH SCREEN CHECKER DI SINI
        home: const AuthCheck(),
      ),
    );
  }
}

// Widget Pengecek Status User
class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool? isFirstRun;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  void _checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    // Default true jika belum pernah dibuka
    setState(() {
      isFirstRun = prefs.getBool('is_first_run') ?? true; 
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Masih Loading cek data
    if (isFirstRun == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 2. Jika First Run -> Ke Onboarding
    if (isFirstRun == true) {
      return const OnboardingScreen();
    }

    // 3. Jika User Lama -> Ke Dashboard
    return const DashboardScreen();
  }
}