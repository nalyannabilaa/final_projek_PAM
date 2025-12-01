// profile_page.dart
// Halaman profil pengguna yang menampilkan informasi user,
// fitur edit profil, upload avatar, dan about us

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../services/local_storage.dart';
import '../../services/session_manager.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_snackbar.dart';
import 'edit_profile_page.dart';
import 'about_us_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _username;
  UserModel? _currentUser;
  File? _avatarImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Memuat data user dari session dan Hive
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final session = await SessionManager.getUserSession();
      final username = session?['username'] as String?;
      if (username != null && username.isNotEmpty) {
        final userBox = LocalStorageService.getUserBox();
        final user = userBox.values.firstWhere(
          (u) => u.username.toLowerCase() == username.toLowerCase(),
          orElse: () => UserModel(
            username: '',
            email: '',
            password: '',
            createdAt: DateTime.now(),
          ),
        );

        if (user.username.isNotEmpty) {
          setState(() {
            _username = username;
            _currentUser = user;

            if (user.avatarPath != null && user.avatarPath!.isNotEmpty) {
              final file = File(user.avatarPath!);
              if (file.existsSync()) {
                _avatarImage = file;
              }
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context,
          "Gagal memuat data profil: $e",
          type: SnackbarType.error,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _saveImagePermanently(String sourcePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final avatarsDir = Directory('${appDir.path}/avatars');

      if (!await avatarsDir.exists()) {
        await avatarsDir.create(recursive: true);
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(sourcePath);
      final fileName = '${_currentUser!.username}_$timestamp$extension';
      final savedPath = '${avatarsDir.path}/$fileName';

      // Copy file ke lokasi permanen
      final sourceFile = File(sourcePath);
      await sourceFile.copy(savedPath);

      return savedPath;
    } catch (e) {
      print('Error saving image: $e');
      return null;
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {

        final savedPath = await _saveImagePermanently(pickedFile.path);

        if (savedPath != null) {
          final result = await LocalStorageService.updateUserAvatar(
            username: _currentUser!.username,
            avatarPath: savedPath,
          );

          if (result['success']) {
            setState(() {
              _avatarImage = File(savedPath);
              _currentUser = result['user'];
            });

            if (mounted) {
              CustomSnackbar.show(
                context,
                "Foto profil berhasil diubah!",
                type: SnackbarType.success,
              );
            }
          } else {
            if (mounted) {
              CustomSnackbar.show(
                context,
                result['message'] ?? "Gagal menyimpan foto profil",
                type: SnackbarType.error,
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context,
          "Gagal memilih gambar: $e",
          type: SnackbarType.error,
        );
      }
    }
  }

  /// Logout dan kembali ke halaman login
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'Konfirmasi Logout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A8273),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await LocalStorageService.logoutUser();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4A8273), Color(0xFFAFCFBD)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : _currentUser == null
              ? _buildErrorState()
              : _buildProfileContent(),
        ),
      ),
    );
  }

  /// Widget untuk state error/user tidak ditemukan
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.white70),
          const SizedBox(height: 20),
          Text(
            'Data pengguna tidak ditemukan',
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.white),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE3DE61),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              'Kembali ke Login',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget konten utama profil
  Widget _buildProfileContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header dengan avatar
          _buildProfileHeader(),

          const SizedBox(height: 30),

          // Info cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _buildInfoCard(
                  icon: Icons.person,
                  label: 'Username', 
                  color: const Color.fromARGB(255, 255, 255, 255),//XXX
                  value: _currentUser!.username,
                ),
                const SizedBox(height: 15),
                _buildInfoCard(
                  icon: Icons.email,
                  label: 'Email',
                  color: const Color.fromARGB(255, 255, 255, 255),
                  value: _currentUser!.email,
                ),
                const SizedBox(height: 15),
                _buildInfoCard(
                  icon: Icons.calendar_today,
                  label: 'Bergabung',
                  color: const Color.fromARGB(255, 255, 255, 255),
                  value: _formatDate(_currentUser!.createdAt),
                ),

                const SizedBox(height: 30),

                // Action buttons
                _buildActionButton(
                  icon: Icons.edit,
                  label: 'Edit Profil',
                  color: const Color(0xFFE3DE61),
                  colorcard: const Color.fromARGB(255, 255, 255, 255), //XX
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfilePage(user: _currentUser!),
                      ),
                    );

                    // Reload data jika ada perubahan
                    if (result == true) {
                      _loadUserData();
                    }
                  },
                ),

                const SizedBox(height: 15),

                _buildActionButton(
                  icon: Icons.info,
                  label: 'About Us',
                  color: const Color(0xFF6B9080),
                  colorcard: Colors.white,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutUsPage()),
                    );
                  },
                ),

                const SizedBox(height: 15),

                _buildActionButton(
                  icon: Icons.logout,
                  label: 'Logout',
                  color: const Color(0xFFD32F2F),
                  colorcard: const Color.fromARGB(255, 255, 255, 255),
                  onTap: _logout,
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Widget header profil dengan avatar
  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          // Avatar dengan kemampuan upload
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.white,
                  backgroundImage: _avatarImage != null
                      ? FileImage(_avatarImage!)
                      : null,
                  child: _avatarImage == null
                      ? Text(
                          _currentUser!.username[0].toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4A8273),
                          ),
                        )
                      : null,
                ),
              ),
              // Tombol edit avatar
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3DE61),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Username
          Text(
            _currentUser!.username,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 5),

          // Email
          Text(
            _currentUser!.email,
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  /// Widget card untuk menampilkan informasi user
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4A8273).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF4A8273), size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Widget tombol aksi
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color colorcard,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: colorcard,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }

  /// Format tanggal menjadi string yang mudah dibaca
  String _formatDate(DateTime date) {
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
