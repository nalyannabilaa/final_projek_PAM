import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 🔹 Inisialisasi di Splash
  static Future<void> initialize() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
    );

    await _notificationsPlugin.initialize(initSettings);

    // ✅ Minta izin notifikasi di awal
    await Permission.notification.request();
  }

  // 🔹 Tampilkan notifikasi langsung (contoh: setelah tambah logbook)
  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'logbook_channel',
      'Logbook Notifications',
      channelDescription: 'Notifikasi untuk pembaruan logbook dan sisa anggaran',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  // 🔹 (Opsional) Jadwal notifikasi harian
  static Future<void> scheduleDailyReminder() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'daily_channel',
      'Daily Reminders',
      channelDescription: 'Pengingat harian untuk update logbook & cek anggaran',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.periodicallyShow(
      0,
      'Cek Logbook Hari Ini',
      'Jangan lupa update logbook dan pantau anggaran ekspedisi!',
      RepeatInterval.daily,
      details,
      androidAllowWhileIdle: true,
    );
  }
}
