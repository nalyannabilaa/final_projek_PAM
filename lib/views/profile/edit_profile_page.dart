// edit_profile_page.dart
// Halaman untuk mengedit informasi profil pengguna
// User dapat mengubah username dan email

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/local_storage.dart';
import '../../widgets/custom_snackbar.dart';

class EditProfilePage extends StatefulWidget {
  final UserModel user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _emailController = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Validasi email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Simpan perubahan profil
  Future<void> _saveChanges() async {
    final newUsername = _usernameController.text.trim();
    final newEmail = _emailController.text.trim();

    // Validasi input
    if (newUsername.isEmpty || newEmail.isEmpty) {
      CustomSnackbar.show(
        context,
        "Username dan email tidak boleh kosong!",
        type: SnackbarType.error,
      );
      return;
    }

    if (!_isValidEmail(newEmail)) {
      CustomSnackbar.show(
        context,
        "Format email tidak valid!",
        type: SnackbarType.error,
      );
      return;
    }

    // Cek apakah ada perubahan
    if (newUsername == widget.user.username && newEmail == widget.user.email) {
      CustomSnackbar.show(
        context,
        "Tidak ada perubahan yang dilakukan",
        type: SnackbarType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userBox = LocalStorageService.getUserBox();

      // Cek username baru jika berubah
      if (newUsername != widget.user.username) {
        final existingUser = userBox.values.any(
          (u) =>
              u.username.toLowerCase() == newUsername.toLowerCase() &&
              u.key != widget.user.key,
        );

        if (existingUser) {
          setState(() => _isLoading = false);
          if (mounted) {
            CustomSnackbar.show(
              context,
              "Username sudah digunakan!",
              type: SnackbarType.error,
            );
          }
          return;
        }
      }

      // Cek email baru jika berubah
      if (newEmail != widget.user.email) {
        final existingEmail = userBox.values.any(
          (u) =>
              u.email.toLowerCase() == newEmail.toLowerCase() &&
              u.key != widget.user.key,
        );

        if (existingEmail) {
          setState(() => _isLoading = false);
          if (mounted) {
            CustomSnackbar.show(
              context,
              "Email sudah terdaftar!",
              type: SnackbarType.error,
            );
          }
          return;
        }
      }

      // Update data user
      widget.user.username = newUsername;
      widget.user.email = newEmail;
      await widget.user.save();

      setState(() => _isLoading = false);

      if (mounted) {
        CustomSnackbar.show(
          context,
          "Profil berhasil diperbarui!",
          type: SnackbarType.success,
        );

        // Kembali ke halaman profil dengan hasil true
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        CustomSnackbar.show(
          context,
          "Gagal memperbarui profil: $e",
          type: SnackbarType.error,
        );
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
          child: Column(
            children: [
              // Custom AppBar
              _buildAppBar(),

              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Header
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.edit_note,
                              size: 80,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              'Edit Profil',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Perbarui informasi akun Anda',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Username Field
                      _buildInputField(
                        controller: _usernameController,
                        label: 'Username',
                        icon: Icons.person,
                        hint: 'Masukkan username baru',
                      ),

                      const SizedBox(height: 20),

                      // Email Field
                      _buildInputField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email,
                        hint: 'Masukkan email baru',
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 40),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE3DE61),
                            foregroundColor: Colors.white,
                            elevation: 5,
                            shadowColor: Colors.black38,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            disabledBackgroundColor: Colors.grey,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'SIMPAN PERUBAHAN',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget custom AppBar
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'Kembali',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Widget input field dengan label
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
            ),
          ),
        ),
      ],
    );
  }
}