import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'db_helper.dart'; // Import file database yang baru dibuat
import 'history_screen.dart';
import 'login_screen.dart';
import 'recap_screen.dart';
import 'notification_helper.dart';

// void main() {
//   runApp(const MyApp());
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Setup Notifikasi
  await NotificationHelper.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Finance',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(
          0xFFF5F6FA,
        ), // Background abu sangat muda
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0052D4), // Biru Corporate Modern
          primary: const Color(0xFF0052D4),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(), // Font Modern
      ),
      home: const LoginScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  bool _isObscured = false;

  // Variabel penampung data dari Database
  List<Map<String, dynamic>> _assets = [];
  List<Map<String, dynamic>> _goals = [];
  bool _isLoading = true;
  // Daftar Pilihan Icon Brand (Preset)
  // DATA PRESET LOGO ASLI (URL)
  // DATA PRESET (DENGAN OPSI LAINNYA)
  final List<Map<String, dynamic>> brandPresets = [
    {'slug': 'bca', 'name': 'myBCA', 'url': 'https://logo.clearbit.com/bca.co.id', 'color': 0xFF0052D4},
    {'slug': 'livin', 'name': 'Livin', 'url': 'https://logo.clearbit.com/bankmandiri.co.id', 'color': 0xFFFFB700},
    {'slug': 'brimo', 'name': 'BRImo', 'url': 'https://logo.clearbit.com/bri.co.id', 'color': 0xFF00529C},
    {'slug': 'bni', 'name': 'BNI', 'url': 'https://logo.clearbit.com/bni.co.id', 'color': 0xFFF15A23},
    {'slug': 'jago', 'name': 'Bank Jago', 'url': 'https://logo.clearbit.com/jago.com', 'color': 0xFFF6A302},
    {'slug': 'gopay', 'name': 'GoPay', 'url': 'https://logo.clearbit.com/gojek.com', 'color': 0xFF00AA13},
    {'slug': 'ovo', 'name': 'OVO', 'url': 'https://logo.clearbit.com/ovo.id', 'color': 0xFF4C3494},
    {'slug': 'shopee', 'name': 'ShopeePay', 'url': 'https://logo.clearbit.com/shopee.co.id', 'color': 0xFFEE4D2D},
    {'slug': 'dana', 'name': 'DANA', 'url': 'https://logo.clearbit.com/dana.id', 'color': 0xFF118EE9},
    {'slug': 'stockbit', 'name': 'Stockbit', 'url': 'https://logo.clearbit.com/stockbit.com', 'color': 0xFF212121},
    {'slug': 'bibit', 'name': 'Bibit', 'url': 'https://logo.clearbit.com/bibit.id', 'color': 0xFF2E7D32},
    {'slug': 'ajaib', 'name': 'Ajaib', 'url': 'https://logo.clearbit.com/ajaib.co.id', 'color': 0xFF007AFF},
    {'slug': 'cash', 'name': 'Cash', 'url': 'CASH', 'color': 0xFF4CAF50}, // Khusus Cash
    // OPSI BARU: LAINNYA
    {'slug': 'other', 'name': 'Lainnya', 'url': 'OTHER', 'color': 0xFF9E9E9E}, 
  ];

  // --- KODE YANG HILANG (HELPER GAMBAR) ---

  // 1. Helper untuk mendapatkan Image Path/URL
  // String? _getLogoImage(String slug) {
  //   try {
  //     return brandPresets.firstWhere(
  //       (element) => element['slug'] == slug,
  //     )['image'];
  //   } catch (e) {
  //     return null;
  //   }
  // }

  // 2. FUNGSI WIDGET PINTAR (Bisa baca Asset atau Network)
  // WIDGET LOGO PINTAR (Support URL, Asset, & Icon Lainnya)
  Widget _buildLogoWidget(String? source, double size) {
    // 1. Handle Opsi "Lainnya"
    if (source == 'OTHER') {
      return Icon(Icons.account_balance_wallet, size: size, color: Colors.grey);
    }
    // 2. Handle Opsi "Cash"
    if (source == 'CASH') {
      return Icon(Icons.money, size: size, color: Colors.green);
    }
    
    // 3. Handle URL Gambar (Internet)
    if (source != null && source.startsWith('http')) {
      return Image.network(
        source,
        width: size, height: size, fit: BoxFit.contain,
        errorBuilder: (ctx, err, stack) {
          // Jika gambar gagal loading, tampilkan inisial nama bank (biar gak icon rusak)
          return Icon(Icons.account_balance, size: size, color: Colors.grey);
        },
      );
    }

    // 4. Fallback jika null (Asset lokal jika ada)
    return Icon(Icons.image, size: size, color: Colors.grey);
  }

  // Update juga helper getLogoImage biar sinkron dengan variabel baru 'url'
  String? _getLogoImage(String slug) {
    try {
      return brandPresets.firstWhere((element) => element['slug'] == slug)['url'];
    } catch (e) {
      return 'OTHER';
    }
  }

  // --- BATAS KODE YANG HILANG ---

  // Fungsi Helper untuk cari URL berdasarkan slug
  String? _getLogoUrl(String slug) {
    try {
      return brandPresets.firstWhere(
        (element) => element['slug'] == slug,
      )['url'];
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshData();
    _setupNotifications(); // <-- Panggil fungsi setup
  }

  // Fungsi Setup Notifikasi
  void _setupNotifications() async {
    // 1. Minta Izin (Android 13+)
    await NotificationHelper.requestPermission();
    
    // 2. Jadwalkan Jam 20:00 (Malam) Setiap Hari
    // Anda bisa ubah angkanya, misal jam 8 pagi (hour: 8, minute: 0)
    await NotificationHelper.scheduleDailyNotification(hour: 20, minute: 0); 
  }

  // Fungsi mengambil data segar dari Database
  void _refreshData() async {
    final dataAssets = await DatabaseHelper.instance.getAssets();
    final dataGoals = await DatabaseHelper.instance.getGoals();

    setState(() {
      _assets = dataAssets;
      _goals = dataGoals;
      _isLoading = false;
    });
  }

  // Fungsi Format Rupiah
  String formatRupiah(num number) {
    if (_isObscured) return "Rp •••••••";
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatCurrency.format(number);
  }

  // Hitung Total Aset
  double get totalAssets =>
      _assets.fold(0, (sum, item) => sum + (item['balance'] as int));

  // --- Dialog Tambah Aset Baru (DENGAN PILIHAN ICON) ---
  // --- FORM ASET (BISA TAMBAH & EDIT) ---
  // --- FORM ASET (DENGAN OPSI LAINNYA) ---
  void _showAddAssetDialog({Map<String, dynamic>? assetToEdit}) {
    final isEditMode = assetToEdit != null;
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    
    // Default
    Map<String, dynamic> selectedBrand = brandPresets[0];

    if (isEditMode) {
      nameController.text = assetToEdit['name'];
      balanceController.text = assetToEdit['balance'].toString();
      try {
        selectedBrand = brandPresets.firstWhere((e) => e['slug'] == assetToEdit['logoSlug']);
      } catch (e) {
        // Jika tidak ada di preset (berarti custom/lainnya), set ke Other
        selectedBrand = brandPresets.last; 
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 20),
                    
                    // HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isEditMode ? "Edit Aset" : "Tambah Aset", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                        if (isEditMode)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                               await DatabaseHelper.instance.deleteAsset(assetToEdit['id']);
                               Navigator.pop(context);
                               _refreshData();
                            },
                          )
                      ],
                    ),
                    
                    const SizedBox(height: 20),

                    // GRID LOGO (DENGAN "LAINNYA")
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: brandPresets.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4, childAspectRatio: 0.8, mainAxisSpacing: 10, crossAxisSpacing: 10,
                      ),
                      itemBuilder: (context, index) {
                        final brand = brandPresets[index];
                        final isSelected = selectedBrand['slug'] == brand['slug'];

                        return InkWell(
                          onTap: () {
                            setModalState(() {
                              selectedBrand = brand;
                              // LOGIC PENTING:
                              // Jika pilih "Lainnya", Kosongkan nama biar user ngetik
                              // Jika pilih Bank, Auto isi namanya
                              if (brand['slug'] == 'other') {
                                nameController.clear(); 
                              } else {
                                nameController.text = brand['name'];
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected ? Color(brand['color']).withOpacity(0.1) : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: isSelected ? Color(brand['color']) : Colors.grey.shade200, width: isSelected ? 2 : 1),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(width: 30, height: 30, child: _buildLogoWidget(brand['url'], 30)),
                                const SizedBox(height: 5),
                                Text(
                                  brand['name'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 9, 
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Color(brand['color']) : Colors.black87
                                  ),
                                  textAlign: TextAlign.center, maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                    
                    // FORM NAMA (Bisa diedit kalau pilih Lainnya)
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "Nama Akun", 
                        hintText: selectedBrand['slug'] == 'other' ? "Contoh: Bank Jatim / Seabank" : null,
                        filled: true, fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: balanceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Saldo (Rp)", filled: true, fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),

                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity, height: 55,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.isNotEmpty && balanceController.text.isNotEmpty) {
                            final data = {
                              'name': nameController.text,
                              'balance': int.parse(balanceController.text),
                              'type': 'BANK',
                              'colorCode': selectedBrand['color'],
                              'logoSlug': selectedBrand['slug']
                            };

                            if (isEditMode) {
                              await DatabaseHelper.instance.updateAsset(assetToEdit['id'], data);
                            } else {
                              await DatabaseHelper.instance.addAsset(data);
                            }
                            _refreshData();
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        child: Ink(
                          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF003973), Color(0xFF0052D4)]), borderRadius: BorderRadius.circular(15)),
                          child: Container(alignment: Alignment.center, child: Text("Simpan", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  // --- MENU AKSI GOALS (TABUNG, EDIT, HAPUS) ---
  void _showGoalOptions(Map<String, dynamic> goal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              goal['name'],
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Target: ${formatRupiah(goal['targetAmount'])}",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // MENU 1: TABUNG (ISI SALDO)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.savings, color: Colors.green),
              ),
              title: Text(
                "Tabung / Update Saldo",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                "Tambah progres tabunganmu",
                style: GoogleFonts.poppins(fontSize: 11),
              ),
              onTap: () {
                Navigator.pop(context); // Tutup menu dulu
                _showEditGoalDialog(
                  goal: goal,
                  isSavingsMode: true,
                ); // Buka dialog mode "Nabung"
              },
            ),

            // MENU 2: EDIT
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, color: Colors.blue),
              ),
              title: Text(
                "Edit Rincian",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                "Ubah nama atau target harga",
                style: GoogleFonts.poppins(fontSize: 11),
              ),
              onTap: () {
                Navigator.pop(context);
                _showEditGoalDialog(
                  goal: goal,
                  isSavingsMode: false,
                ); // Buka dialog mode "Edit"
              },
            ),

            // MENU 3: HAPUS
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete, color: Colors.red),
              ),
              title: Text(
                "Hapus Goals",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              onTap: () async {
                // Konfirmasi Hapus
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Hapus Impian Ini?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Batal"),
                      ),
                      TextButton(
                        onPressed: () async {
                          await DatabaseHelper.instance.deleteGoal(goal['id']);
                          Navigator.pop(ctx); // Tutup Alert
                          Navigator.pop(context); // Tutup BottomSheet
                          _refreshData();
                        },
                        child: const Text(
                          "Hapus",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- DIALOG FORM GOALS (BISA UNTUK NABUNG ATAU EDIT) ---
  void _showEditGoalDialog({
    required Map<String, dynamic> goal,
    required bool isSavingsMode,
  }) {
    final nameController = TextEditingController(text: goal['name']);
    final targetController = TextEditingController(
      text: goal['targetAmount'].toString(),
    );
    final currentController = TextEditingController(
      text: goal['currentAmount'].toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isSavingsMode ? "Update Tabungan" : "Edit Goals",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isSavingsMode) ...[
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Nama Barang"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: targetController,
                decoration: const InputDecoration(
                  labelText: "Target Harga (Rp)",
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
            ],

            // Kolom Saldo Terkini (Fokus utama jika mode Nabung)
            TextField(
              controller: currentController,
              decoration: InputDecoration(
                labelText: "Uang Terkumpul Saat Ini (Rp)",
                filled:
                    isSavingsMode, // Kalau mode nabung, dikasih warna biar fokus
                fillColor: isSavingsMode ? Colors.green.withOpacity(0.1) : null,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              autofocus: isSavingsMode, // Langsung muncul keyboard
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.updateGoal(goal['id'], {
                'name': nameController.text,
                'targetAmount': int.parse(targetController.text),
                'currentAmount': int.parse(currentController.text),
                'colorCode': goal['colorCode'], // Tetap pakai warna lama
              });
              _refreshData();
              Navigator.pop(ctx);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  // --- 1. Dialog Tambah Transaksi (Pemasukan / Pengeluaran) ---
  // --- MODERN TRANSACTION FORM (PEMASUKAN & PENGELUARAN) ---
  void _showTransactionDialog(String type) {
    // Tentukan Warna Tema: Hijau (Masuk) atau Merah (Keluar)
    final isIncome = type == 'IN';
    final themeColor = isIncome ? Colors.green : Colors.redAccent;
    final title = isIncome ? "Pemasukan Baru" : "Pengeluaran Baru";

    final titleController = TextEditingController();
    final amountController = TextEditingController();
    
    // Default aset pertama
    int? selectedAssetId = _assets.isNotEmpty ? _assets.first['id'] : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
              ),
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. HANDLE BAR
                    Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 20),

                    // 2. HEADER JUDUL
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: themeColor.withOpacity(0.1), shape: BoxShape.circle),
                          child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: themeColor),
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(isIncome ? "Dapat uang dari mana?" : "Uangnya buat beli apa?", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 25),

                    // 3. INPUT JUDUL (e.g. Gaji)
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: "Judul Transaksi",
                        hintText: isIncome ? "Contoh: Gaji Bulanan" : "Contoh: Beli Kopi",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // 4. INPUT NOMINAL
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Nominal (Rp)",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        prefixIcon: const Padding(padding: EdgeInsets.all(15), child: Text("Rp", style: TextStyle(fontWeight: FontWeight.bold))),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // 5. PILIH SUMBER DANA (DROPDOWN MODERN)
                    Text("Sumber Dana:", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedAssetId,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          items: _assets.map((asset) {
                            return DropdownMenuItem<int>(
                              value: asset['id'],
                              child: Row(
                                children: [
                                  // Logo Kecil
                                  SizedBox(width: 24, height: 24, child: _buildLogoWidget(_getLogoImage(asset['logoSlug'] ?? 'cash'), 24)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(asset['name'], style: GoogleFonts.poppins(fontSize: 14)),
                                        Text("Saldo: ${formatRupiah(asset['balance'])}", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setModalState(() {
                              selectedAssetId = value;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // 6. TOMBOL SIMPAN (GRADIENT)
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (titleController.text.isNotEmpty && amountController.text.isNotEmpty && selectedAssetId != null) {
                            int amount = int.parse(amountController.text);
                            
                            // 1. Simpan Transaksi
                            await DatabaseHelper.instance.addTransaction({
                              'title': titleController.text,
                              'amount': amount,
                              'type': type,
                              'date': DateTime.now().toString(),
                              'assetId': selectedAssetId
                            });

                            // 2. Update Saldo
                            final asset = _assets.firstWhere((element) => element['id'] == selectedAssetId);
                            int current = asset['balance'];
                            int newBalance = isIncome ? (current + amount) : (current - amount);

                            await DatabaseHelper.instance.updateAssetBalance(selectedAssetId!, newBalance);

                            _refreshData();
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            // Gradient Warna sesuai Tipe (Hijau/Merah)
                            gradient: LinearGradient(
                              colors: isIncome 
                                ? [Colors.green, Colors.green.shade700] 
                                : [Colors.redAccent, Colors.red],
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: Text("Simpan Transaksi", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  // --- 2. Dialog Tambah Goals Baru ---
  // --- MODERN GOALS FORM (BOTTOM SHEET) ---
  void _showAddGoalDialog() {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    final currentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Agar bisa full screen & geser saat keyboard muncul
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            // Padding bawah otomatis mengikuti tinggi keyboard
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
              ),
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. HANDLE BAR
                    Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 20),

                    // 2. HEADER DENGAN ICON
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.stars_rounded, color: Colors.orange, size: 32),
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Goals Impian", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text("Tentukan target barumu!", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 25),

                    // 3. INPUT NAMA BARANG
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "Nama Barang / Impian",
                        hintText: "Contoh: iPhone 15 Pro",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // 4. INPUT TARGET HARGA
                    TextField(
                      controller: targetController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Target Harga",
                        prefixText: "Rp ",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // 5. INPUT TABUNGAN SAAT INI (Opsional)
                    TextField(
                      controller: currentController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Sudah Terkumpul (Opsional)",
                        hintText: "0",
                        prefixText: "Rp ",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // 6. TOMBOL SIMPAN
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.isNotEmpty && targetController.text.isNotEmpty) {
                            await DatabaseHelper.instance.addGoal({
                              'name': nameController.text,
                              'targetAmount': int.parse(targetController.text),
                              'currentAmount': currentController.text.isEmpty ? 0 : int.parse(currentController.text),
                              'colorCode': 0xFF0052D4 // Default Biru
                            });
                            _refreshData();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Goals berhasil dibuat! Semangat nabung!"), backgroundColor: Colors.green));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF003973), Color(0xFF0052D4)]),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: Text("Mulai Wujudkan", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10), // Extra space bawah
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  // --- FITUR TRANSFER (PINDAH SALDO) ---
  // --- FITUR TRANSFER (FIX: ANTI OVERFLOW KEYBOARD) ---
  void _showTransferDialog() {
    if (_assets.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Minimal harus punya 2 dompet untuk transfer!"), backgroundColor: Colors.red));
      return;
    }

    final amountController = TextEditingController();
    Map<String, dynamic> sourceAsset = _assets[0];
    Map<String, dynamic> destAsset = _assets[1];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Wajib true
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            // PADDING INI MENJAMIN TAMPILAN NAIK SAAT KEYBOARD MUNCUL
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              // BATASI TINGGI MAKSIMAL AGAR TIDAK LEPAS KE ATAS
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
              ),
              // WRAP DENGAN SCROLL VIEW AGAR BISA DISCROLL
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 20),
                    
                    Text("Transfer Saldo", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    // 1. DARI (SUMBER)
                    Text("Dari Dompet:", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: sourceAsset['id'],
                          isExpanded: true,
                          items: _assets.map((asset) {
                            return DropdownMenuItem<int>(
                              value: asset['id'],
                              child: Row(
                                children: [
                                  SizedBox(width: 24, height: 24, child: _buildLogoWidget(asset['logoSlug'], 24)),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(asset['name'], style: GoogleFonts.poppins())),
                                  Text(formatRupiah(asset['balance']), style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setModalState(() {
                              sourceAsset = _assets.firstWhere((e) => e['id'] == value);
                              // Auto Swap Logic
                              if (sourceAsset['id'] == destAsset['id']) {
                                destAsset = _assets.firstWhere((e) => e['id'] != sourceAsset['id']);
                              }
                            });
                          },
                        ),
                      ),
                    ),

                    // ICON PANAH
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Icon(Icons.arrow_downward_rounded, color: Colors.blue[800], size: 28),
                      ),
                    ),

                    // 2. KE (TUJUAN)
                    Text("Ke Dompet:", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: destAsset['id'],
                          isExpanded: true,
                          items: _assets.map((asset) {
                            return DropdownMenuItem<int>(
                              value: asset['id'],
                              child: Row(
                                children: [
                                  SizedBox(width: 24, height: 24, child: _buildLogoWidget(asset['logoSlug'], 24)),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(asset['name'], style: GoogleFonts.poppins())),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setModalState(() {
                              destAsset = _assets.firstWhere((e) => e['id'] == value);
                              // Auto Swap Logic
                              if (destAsset['id'] == sourceAsset['id']) {
                                sourceAsset = _assets.firstWhere((e) => e['id'] != destAsset['id']);
                              }
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 3. NOMINAL
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Nominal Transfer",
                        prefixText: "Rp ",
                        filled: true, fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),

                    const SizedBox(height: 30),
                    
                    // TOMBOL CONFIRM
                    SizedBox(
                      width: double.infinity, height: 55,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (amountController.text.isNotEmpty) {
                            int amount = int.parse(amountController.text);
                            
                            if (sourceAsset['balance'] < amount) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saldo tidak cukup!"), backgroundColor: Colors.red));
                              return;
                            }

                            // Update Database
                            await DatabaseHelper.instance.updateAssetBalance(sourceAsset['id'], sourceAsset['balance'] - amount);
                            await DatabaseHelper.instance.updateAssetBalance(destAsset['id'], destAsset['balance'] + amount);

                            await DatabaseHelper.instance.addTransaction({
                              'title': "Transfer ke ${destAsset['name']}",
                              'amount': amount, 'type': 'OUT', 'date': DateTime.now().toString(), 'assetId': sourceAsset['id']
                            });
                            
                            await DatabaseHelper.instance.addTransaction({
                              'title': "Terima dari ${sourceAsset['name']}",
                              'amount': amount, 'type': 'IN', 'date': DateTime.now().toString(), 'assetId': destAsset['id']
                            });

                            _refreshData();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Berhasil transfer Rp ${formatRupiah(amount)}"), backgroundColor: Colors.green));
                          }
                        },
                        style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        child: Ink(
                          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF003973), Color(0xFF0052D4)]), borderRadius: BorderRadius.circular(15)),
                          child: Container(alignment: Alignment.center, child: Text("Konfirmasi Transfer", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10), // Jarak aman extra di bawah
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // HEADER SECTION
                  Container(
                    padding: const EdgeInsets.only(
                      top: 60,
                      left: 20,
                      right: 20,
                      bottom: 30,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF003973),
                          Color(0xFFE5E5BE),
                          Color(0xFF0052D4),
                        ],
                        stops: [0.0, 0.9, 1.0],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Selamat Pagi,",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  "Sultan Finance",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {},
                                ),
                                const CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    'https://i.pravatar.cc/150?img=12',
                                  ),
                                  radius: 20,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Text(
                          "Total Portofolio",
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Text(
                              formatRupiah(totalAssets),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: Icon(
                                _isObscured
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.white70,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isObscured = !_isObscured;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // SECTION: DOMPET & ASET
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Dompet & Aset",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        InkWell(
                          onTap: _showAddAssetDialog, // KLIK INI UNTUK NAMBAH
                          child: Text(
                            "+ Tambah",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.blue[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // LIST HORIZONTAL ASET
                  // LIST HORIZONTAL ASET (LOGO ASLI)
                  SizedBox(
                    height: 150, // Sedikit lebih tinggi biar logo muat
                    child: _assets.isEmpty
                        ? Center(
                            child: Text(
                              "Belum ada aset",
                              style: GoogleFonts.poppins(),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(left: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: _assets.length,
                            itemBuilder: (context, index) {
                              final asset = _assets[index];
                              final String slug = asset['logoSlug'] ?? 'cash';
                              final String? logoUrl = _getLogoUrl(slug);
                              final isCash = slug == 'cash';

                              return Container(
                                width: 160,
                                margin: const EdgeInsets.only(
                                  right: 15,
                                  bottom: 10,
                                ),
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // HEADER: LOGO ASLI
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          height: 40,
                                          width: 60,
                                          alignment: Alignment.centerLeft,
                                          child: isCash
                                              ? Icon(
                                                  Icons.money,
                                                  size: 30,
                                                  color: Color(
                                                    asset['colorCode'],
                                                  ),
                                                )
                                              : Image.network(
                                                  logoUrl ?? '',
                                                  fit: BoxFit.contain,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => const Icon(
                                                        Icons.account_balance,
                                                      ),
                                                ),
                                        ),
                                        // Tombol Edit (Titik Tiga)
                                        InkWell(
                                          onTap: () {
                                            // Panggil form edit dengan membawa data aset yang diklik
                                            _showAddAssetDialog(
                                              assetToEdit: asset,
                                            );
                                          },
                                          child: const Icon(
                                            Icons.more_vert,
                                            color: Colors.grey,
                                            size: 24,
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Detail Saldo
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          asset['name'],
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          formatRupiah(asset['balance']),
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  // SECTION: MENU CEPAT
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      children: [
                        // Tombol MASUK (Income)
                        InkWell(
                          onTap: () => _showTransactionDialog('IN'),
                          child: _buildMenuIcon(
                            Icons.arrow_upward,
                            "Masuk",
                            Colors.green,
                          ),
                        ),
                        // Tombol KELUAR (Expense)
                        InkWell(
                          onTap: () => _showTransactionDialog('OUT'),
                          child: _buildMenuIcon(
                            Icons.arrow_downward,
                            "Keluar",
                            Colors.red,
                          ),
                        ),
                        // Tombol Transfer (Sementara kosong/dummy)
                        // Tombol Transfer (Sementara kosong/dummy)
                        // Tombol Transfer (AKTIF)
                        InkWell(
                          onTap: _showTransferDialog, // <-- Panggil fungsi ini
                          child: _buildMenuIcon(
                            Icons.swap_horiz,
                            "Transfer",
                            Colors.blue,
                          ),
                        ),
                        // Tombol Riwayat (Sementara kosong/dummy)
                        // Tombol Riwayat
                        InkWell(
                          onTap: () {
                            // Navigasi ke Halaman History
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HistoryScreen(),
                              ),
                            ).then(
                              (_) => _refreshData(),
                            ); // Saat kembali, refresh data saldo (siapa tau ada yg berubah)
                          },
                          child: _buildMenuIcon(
                            Icons.history,
                            "Riwayat",
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // SECTION: GOALS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Goals Impian",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        InkWell(
                          onTap:
                              _showAddGoalDialog, // Panggil fungsi tambah goals
                          child: Icon(
                            Icons.add_circle,
                            color: Colors.blue[800],
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // LIST GOALS
                  // LIST GOALS (INTERAKTIF)
                  _goals.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              "Belum ada goals",
                              style: GoogleFonts.poppins(color: Colors.grey),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _goals.length,
                          itemBuilder: (context, index) {
                            final goal = _goals[index];
                            double percent =
                                (goal['currentAmount'] / goal['targetAmount']);
                            if (percent > 1.0) percent = 1.0;

                            return InkWell(
                              onTap: () {
                                // KLIK DISINI UNTUK BUKA MENU AKSI
                                _showGoalOptions(goal);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 15),
                                padding: const EdgeInsets.all(15),
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
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Color(
                                          goal['colorCode'],
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.star,
                                        color: Color(goal['colorCode']),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                goal['name'],
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                "${(percent * 100).toStringAsFixed(0)}%",
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(
                                                    goal['colorCode'],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          LinearPercentIndicator(
                                            lineHeight: 8.0,
                                            percent: percent,
                                            progressColor: Color(
                                              goal['colorCode'],
                                            ),
                                            backgroundColor: Colors.grey[200],
                                            barRadius: const Radius.circular(
                                              10,
                                            ),
                                            padding: EdgeInsets.zero,
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            "${formatRupiah(goal['currentAmount'])} / ${formatRupiah(goal['targetAmount'])}",
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Indikator panah kecil agar user tahu ini bisa diklik
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
      // ... SISA CODE SAMA (FAB & BottomNavBar) ...
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF0052D4),
        shape: const CircleBorder(),
        elevation: 5,
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 30),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.home, color: Color(0xFF0052D4)),
                onPressed: () {},
              ),
              // TOMBOL REKAP (PIE CHART)
              IconButton(
                icon: const Icon(
                  Icons.pie_chart_outline,
                  color: Colors.grey,
                  size: 28,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecapScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 40),
              IconButton(
                icon: const Icon(Icons.wallet, color: Colors.grey),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.grey),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Helper Icon
  Widget _buildMenuIcon(IconData icon, String label, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }
}
