//digunakan untuk mengelola penyimpanan lokal data pengguna menggunakan Hive,
// termasuk registrasi, login, logout, dan pengambilan data user.
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'session_manager.dart';

class LocalStorageService {
  static const String _userBoxName = 'users';

  // ✅ Initialize Hive
  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }

    await Hive.openBox<UserModel>(_userBoxName);
  }

  // ✅ Get user box
  static Box<UserModel> getUserBox() {
    return Hive.box<UserModel>(_userBoxName);
  }

  // ✅ Hash password (SHA256)
  static String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ✅ Register user baru
  static Future<Map<String, dynamic>> registerUser({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final userBox = getUserBox();

      // Cek apakah username sudah ada
      final existingUser = userBox.values.firstWhere(
        (user) => user.username.toLowerCase() == username.toLowerCase(),
        orElse: () => UserModel(
          username: '',
          email: '',
          password: '',
          createdAt: DateTime.now(),
        ),
      );

      if (existingUser.username.isNotEmpty) {
        return {'success': false, 'message': 'Username sudah digunakan!'};
      }

      // Cek apakah email sudah digunakan
      final existingEmail = userBox.values.firstWhere(
        (user) => user.email.toLowerCase() == email.toLowerCase(),
        orElse: () => UserModel(
          username: '',
          email: '',
          password: '',
          createdAt: DateTime.now(),
        ),
      );

      if (existingEmail.email.isNotEmpty) {
        return {'success': false, 'message': 'Email sudah terdaftar!'};
      }

      // Hash password
      final hashedPassword = hashPassword(password);

      // Buat user baru
      final newUser = UserModel(
        username: username,
        email: email,
        password: hashedPassword,
        createdAt: DateTime.now(),
      );

      await userBox.add(newUser);
      await userBox.flush(); // pastikan tersimpan
      return {
        'success': true,
        'message': 'Registrasi berhasil!',
        'user': newUser,
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ✅ Login user
  static Future<Map<String, dynamic>> loginUser({
    required String username,
    required String password,
  }) async {
    try {
      final userBox = getUserBox();
      final hashedPassword = hashPassword(password);
      final user = userBox.values.firstWhere(
        (user) => user.username.toLowerCase() == username.toLowerCase(),
        orElse: () => UserModel(
          username: '',
          email: '',
          password: '',
          createdAt: DateTime.now(),
        ),
      );

      if (user.username.isEmpty) {
        return {'success': false, 'message': 'Username tidak ditemukan!'};
      }

      if (user.password != hashedPassword) {
        return {'success': false, 'message': 'Password salah!'};
      }

      // ✅ Simpan session ke Shared Preferences
      await SessionManager.saveUserSession(
        username: user.username,
        leaderId: user.key ?? 1, // gunakan key Hive sebagai ID unik user
      );

      return {
        'success': true,
        'message': 'Login berhasil!',
        'user': user,
        'leaderId': user.key ?? 1,
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ✅ Logout user (hapus sesi)
  static Future<void> logoutUser() async {
    await SessionManager.clearSession();
  }

  // ✅ Ambil semua user
  static List<UserModel> getAllUsers() {
    final userBox = getUserBox();
    return userBox.values.toList();
  }

  // ✅ Hapus user
  static Future<bool> deleteUser(String username) async {
    try {
      final userBox = getUserBox();
      final userKey = userBox.keys.firstWhere((key) {
        final user = userBox.get(key);
        return user?.username == username;
      }, orElse: () => null);

      if (userKey != null) {
        await userBox.delete(userKey);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ✅ Hapus semua data (debug)
  static Future<void> clearAllData() async {
    if (!Hive.isBoxOpen(_userBoxName)) {
      await Hive.openBox<UserModel>(_userBoxName);
    }
    final userBox = getUserBox();
    await userBox.clear();
  }
}
