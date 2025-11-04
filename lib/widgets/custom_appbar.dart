import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CustomAppBar extends StatelessWidget {
  final String username;

  const CustomAppBar({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');

    return Container(
      padding: const EdgeInsets.all(20), // ⚠️ UBAH: 24 → 20
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A8273), Color(0xFF6FA88E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          // ✅ TAMBAHKAN: Expanded untuk mencegah overflow
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $username! 👋', // ⚠️ UBAH: Lebih ringkas
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22, // ⚠️ UBAH: 24 → 22
                  ),
                  maxLines: 1, // ✅ TAMBAHKAN: Max 1 baris
                  overflow: TextOverflow.ellipsis, // ✅ TAMBAHKAN: Truncate dengan ...
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(now),
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13, // ⚠️ UBAH: 14 → 13
                  ),
                  maxLines: 1, // ✅ TAMBAHKAN: Max 1 baris
                  overflow: TextOverflow.ellipsis, // ✅ TAMBAHKAN
                ),
              ],
            ),
          ),
          // ✅ TAMBAHKAN: Avatar user
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : 'U',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4A8273),
              ),
            ),
          ),
        ],
      ),
    );
  }
}