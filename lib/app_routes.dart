import 'package:flutter/material.dart';
import 'views/auth/login_page.dart';
import 'views/auth/registrasi_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginPage(),
    register: (context) => const RegisterPage(),
    // home: (context) => BukuGridPage(username: ''),
  };
}