import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'session_manager.dart';

class LocalStorageService {
  static const String _userBoxName = 'users';

  // Initialize Hive
  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }

    await Hive.openBox<UserModel>(_userBoxName);
  }

  // Get user box
  static Box<UserModel> getUserBox() {
    return Hive.box<UserModel>(_userBoxName);
  }

  // Hash password (SHA256)
  static String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Register user baru
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

  // Login user
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

      await SessionManager.saveUserSession(
        username: user.username,
        leaderId: user.key ?? 1, 
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

  static Future<void> logoutUser() async {
    await SessionManager.clearSession();
  }

  //avatar
  static Future<Map<String, dynamic>> updateUserAvatar({
    required String username,
    required String avatarPath,
  }) async {
    try {
      final userBox = getUserBox();
      
      // Cari user berdasarkan username
      final userKey = userBox.keys.firstWhere(
        (key) {
          final user = userBox.get(key);
          return user?.username.toLowerCase() == username.toLowerCase();
        },
        orElse: () => null,
      );

      if (userKey == null) {
        return {'success': false, 'message': 'User tidak ditemukan!'};
      }

      // Update avatar path
      final user = userBox.get(userKey);
      if (user != null) {
        user.avatarPath = avatarPath;
        await user.save(); // Simpan perubahan
        await userBox.flush();
        
        return {
          'success': true,
          'message': 'Avatar berhasil diperbarui!',
          'user': user,
        };
      }

      return {'success': false, 'message': 'Gagal memperbarui avatar!'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Update profile user (username, email, avatar)
  static Future<Map<String, dynamic>> updateUserProfile({
    required String currentUsername,
    String? newUsername,
    String? newEmail,
    String? avatarPath,
  }) async {
    try {
      final userBox = getUserBox();
      
      // Cari user berdasarkan username
      final userKey = userBox.keys.firstWhere(
        (key) {
          final user = userBox.get(key);
          return user?.username.toLowerCase() == currentUsername.toLowerCase();
        },
        orElse: () => null,
      );

      if (userKey == null) {
        return {'success': false, 'message': 'User tidak ditemukan!'};
      }

      final user = userBox.get(userKey);
      if (user != null) {
        // Update fields yang diberikan
        if (newUsername != null && newUsername.isNotEmpty) {
          // Cek apakah username baru sudah digunakan
          final existingUser = userBox.values.firstWhere(
            (u) => u.username.toLowerCase() == newUsername.toLowerCase() && 
                   u.username.toLowerCase() != currentUsername.toLowerCase(),
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
          
          user.username = newUsername;
          
          // Update session juga
          await SessionManager.saveUserSession(
            username: newUsername,
            leaderId: userKey as int,
          );
        }
        
        if (newEmail != null && newEmail.isNotEmpty) {
          // Cek apakah email baru sudah digunakan
          final existingEmail = userBox.values.firstWhere(
            (u) => u.email.toLowerCase() == newEmail.toLowerCase() && 
                   u.email.toLowerCase() != user.email.toLowerCase(),
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
          
          user.email = newEmail;
        }
        
        if (avatarPath != null) {
          user.avatarPath = avatarPath;
        }

        await user.save();
        await userBox.flush();
        
        return {
          'success': true,
          'message': 'Profil berhasil diperbarui!',
          'user': user,
        };
      }

      return {'success': false, 'message': 'Gagal memperbarui profil!'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // Ambil semua user
  static List<UserModel> getAllUsers() {
    final userBox = getUserBox();
    return userBox.values.toList();
  }

  // Hapus user
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

  // Hapus semua data (debug)
  static Future<void> clearAllData() async {
    if (!Hive.isBoxOpen(_userBoxName)) {
      await Hive.openBox<UserModel>(_userBoxName);
    }
    final userBox = getUserBox();
    await userBox.clear();
  }
}