//digunkan untuk splash page dan cek sesi otomatis
import 'package:flutter/material.dart';
import '../../services/session_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../utils/notification_helper.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initApp();
    
  }
  
  Future<void> _initApp() async {
    await NotificationHelper.initialize();

    await _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      final session = await SessionManager.getUserSession();
      await Future.delayed(const Duration(seconds: 2)); // splash animasi

      if (!mounted) return;

      if (session != null &&
          session['username'] != null &&
          session['leaderId'] != null) {
        print(
          'Session found: ${session['username']}, ${session['leaderId']}',
        ); // Debug print
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: {
            'username': session['username'],
            'leaderId': session['leaderId'],
          },
        );
      } else {
        print('No valid session found'); // Debug print
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('Error checking session: $e'); // Debug print
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Color(0xFF4A8273))),
    );
  }
}
