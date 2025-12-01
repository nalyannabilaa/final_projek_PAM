import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/logbook_controller.dart';
import '../../models/logbook_model.dart';
import '../../widgets/custom_snackbar.dart';
import 'edit_logbook_page.dart'; // halaman edit logbook nanti
import '../../widgets/image_preview.dart'; // opsional jika ingin zoom gambar
import '../../controllers/expedition_controller.dart';

class LogbookDetailPage extends StatelessWidget {
  final LogbookModel logbook;

  const LogbookDetailPage({super.key, required this.logbook});

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A8273),
        title: Text(
          'Detail Logbook',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 20),
            _buildInfoSection(
              'Tanggal & Waktu',
              DateFormat('EEEE, d MMM y - HH:mm', 'id_ID').format(logbook.date),
              Icons.access_time,
              const Color.fromARGB(255, 255, 255, 255)!,
            ),
            const SizedBox(height: 16),
            _buildInfoSection(
              'Lokasi',
              '${logbook.location} (${logbook.latitude?.toStringAsFixed(4)}, ${logbook.longitude?.toStringAsFixed(4)})',
              Icons.location_on,
              const Color.fromARGB(255, 255, 255, 255)
            ),
            const SizedBox(height: 16),
            _buildInfoSection(
              'Kondisi Cuaca',
              logbook.weather ?? '-',
              Icons.cloud,
              const Color.fromARGB(255, 255, 255, 255)
            ),
            const SizedBox(height: 16),
            _buildInfoSection(
              'Elevasi',
              logbook.elevation != null
                  ? '${logbook.elevation!.toStringAsFixed(1)} mdpl'
                  : '-',
              Icons.terrain,
              const Color.fromARGB(255, 255, 255, 255)
            ),
            const SizedBox(height: 16),
            _buildBudgetSection(context),
            const SizedBox(height: 16),
            _buildInfoSection('Isi Catatan', logbook.content, Icons.note, const Color.fromARGB(255, 255, 255, 255)),
            if ((logbook.obstacle?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 16),
              _buildInfoSection('Kendala', logbook.obstacle!, Icons.warning, const Color.fromARGB(255, 255, 255, 255)),
            ],
            if ((logbook.suggestion?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 16),
              _buildInfoSection('Saran / Evaluasi', logbook.suggestion!, Icons.lightbulb, const Color.fromARGB(255, 255, 255, 255)),
            ],
            if (logbook.images.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildImageSection(),
            ],
            const SizedBox(height: 30),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  // 🔹 HEADER
  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE3DE61), Color(0xFF5DA290)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            logbook.title,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Oleh: ${logbook.username}',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // 🔹 INFO SECTION
  Widget _buildInfoSection(String title, String value, IconData icon, Color colorcard) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorcard,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF569070)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF2D3436),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 BAGIAN ANGGARAN
  Widget _buildBudgetSection(context) {
  final expeditionController = Provider.of<ExpeditionController>(context, listen: false);
  final expeditionCurrency = expeditionController.activeExpedition?.targetCurrency ?? 'Rp';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Anggaran Harian',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pengeluaran Hari Ini:',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              Text(
                NumberFormat.currency(
                  locale: 'id_ID',
                  symbol: '$expeditionCurrency',
                ).format(logbook.dailyExpense),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.grey),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sisa Anggaran:', style: GoogleFonts.poppins(fontSize: 14)),
              Text(
                NumberFormat.currency(
                  locale: 'id_ID',
                  symbol: '$expeditionCurrency',
                ).format(logbook.remainingBudget),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: logbook.remainingBudget >= 0
                      ? Colors.green[700]
                      : Colors.red[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  // 🔹 FOTO DOKUMENTASI
  Widget _buildImageSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dokumentasi',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: logbook.images.length,
            itemBuilder: (context, index) {
              final imagePath = logbook.images[index];
              return GestureDetector(
                onTap: () {
                  // opsional: buka full image
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      child: Image.file(File(imagePath), fit: BoxFit.cover),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(File(imagePath), fit: BoxFit.cover),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 🔹 TOMBOL AKSI (Edit / Hapus)
  Widget _buildActionButtons(BuildContext context) {
    final controller = context.read<LogbookController>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: () async {
            final updated = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditLogbookPage(logbook: logbook),
              ),
            );
            if (updated == true && context.mounted) {
              CustomSnackbar.show(
                context,
                'Logbook berhasil diperbarui!',
                type: SnackbarType.success,
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE2EF6A),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          icon: const Icon(Icons.edit),
          label: const Text('Edit'),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Konfirmasi Hapus'),
                content: const Text(
                  'Apakah kamu yakin ingin menghapus logbook ini?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batal'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Hapus',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await controller.deleteLogbook(logbook.id, logbook.expeditionId);
              if (context.mounted) {
                Navigator.pop(context);
                CustomSnackbar.show(
                  context,
                  'Logbook berhasil dihapus',
                  type: SnackbarType.error,
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          icon: const Icon(Icons.delete),
          label: const Text('Hapus'),
        ),
      ],
    );
  }
}
