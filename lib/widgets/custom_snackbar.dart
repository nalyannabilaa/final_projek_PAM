//digunakan untuk menampilkan snackbar kustom dengan berbagai tipe (sukses, peringatan, kesalahan, dan kustom)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomSnackbar {
  // 🎨 Warna default sesuai tema LoginPage
  static const Color successColor = Color(0xFF5ADB6B); // Hijau terang
  static const Color warningColor = Color(0xFFE3DE61); // Kuning lembut
  static const Color errorColor = Color(0xFFF76E6E);   // Merah lembut

  /// 🔹 Template utama untuk menampilkan snackbar
  static void show(
    BuildContext context,
    String message, {
    SnackbarType type = SnackbarType.custom,
    Color? customColor,
    IconData? icon,
    int durationSeconds = 2,
  }) {
    // Pilih warna & ikon berdasarkan tipe
    final Color backgroundColor;
    final IconData defaultIcon;

    switch (type) {
      case SnackbarType.success:
        backgroundColor = successColor;
        defaultIcon = Icons.check_circle_outline;
        break;
      case SnackbarType.warning:
        backgroundColor = warningColor;
        defaultIcon = Icons.warning_amber_rounded;
        break;
      case SnackbarType.error:
        backgroundColor = errorColor;
        defaultIcon = Icons.error_outline;
        break;
      case SnackbarType.custom:
      default:
        backgroundColor = customColor ?? Colors.blueGrey;
        defaultIcon = icon ?? Icons.info_outline;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: Duration(seconds: durationSeconds),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon ?? defaultIcon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Enum untuk menentukan tipe snackbar
enum SnackbarType {
  success,
  warning,
  error,
  custom,
}
