import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationHelper {
  static final _notification = FlutterLocalNotificationsPlugin();

  // Inisialisasi Awal
  static Future init() async {
    tz.initializeTimeZones(); // Setup zona waktu

    // Settingan Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    // const androidSettings = AndroidInitializationSettings('notification_icon');
    // Settingan iOS (Default)
    const iosSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notification.initialize(settings);
  }

  // Fungsi Menjadwalkan Notifikasi Harian
  static Future scheduleDailyNotification({required int hour, required int minute}) async {
    await _notification.zonedSchedule(
      0, // ID Notifikasi
      'Waktunya Catat Keuangan! 📝', // Judul
      'Sudah jajan apa hari ini? Yuk catat pengeluaranmu biar ga boncos.', // Isi Pesan
      _scheduleDaily(hour, minute), // <--- PERBAIKAN: Langsung kirim jam & menit
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel', // Channel ID
          'Daily Reminder', // Nama Channel
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Agar berulang setiap hari di jam yg sama
    );
  }

  // Helper konversi waktu (PERBAIKAN: Parameter diganti jadi int hour, int minute)
  static tz.TZDateTime _scheduleDaily(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    // Buat jadwal hari ini pada jam yang ditentukan
    final scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    // Jika waktu sudah lewat hari ini, jadwalkan besok
    return scheduledDate.isBefore(now)
        ? scheduledDate.add(const Duration(days: 1))
        : scheduledDate;
  }
  
  // Fungsi Minta Izin (Khusus Android 13+)
  static Future requestPermission() async {
    await _notification.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  // --- FUNGSI TES LANGSUNG (TANPA JADWAL) ---
  static Future showTestNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'test_channel', // ID Channel
      'Test Notification', // Nama Channel
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notification.show(
      888, // ID Bebas
      'Tes Notifikasi Berhasil! 🎉', 
      'Sistem notifikasi kamu sudah berjalan lancar.', 
      platformChannelSpecifics,
    );
  }
}