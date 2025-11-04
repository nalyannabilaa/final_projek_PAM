import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/expedition_controller.dart';
import '../../models/expedition_model.dart';
import 'edit_expedition_page.dart';
import '../../widgets/custom_snackbar.dart';

class ExpeditionDetailPage extends StatelessWidget {
  final ExpeditionModel expedition;

  const ExpeditionDetailPage({super.key, required this.expedition});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A8273),
        title: Text(
          'Detail Ekspedisi',
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
            _buildHeaderCard(context),
            const SizedBox(height: 20),
            _buildInfoSection('Lokasi', expedition.location, Icons.location_on),
            const SizedBox(height: 16),
            _buildInfoSection(
              'Tanggal',
              '${DateFormat('d MMM y').format(expedition.startDate)} - '
                  '${DateFormat('d MMM y').format(expedition.endDate)}',
              Icons.calendar_today,
            ),
            const SizedBox(height: 16),
            _buildInfoSection(
              'Status Ekspedisi',
              expedition.status.toUpperCase(),
              Icons.flag,
              color: _getStatusColor(expedition.status),
            ),
            const SizedBox(height: 16),
            _buildBudgetSection(),
            const SizedBox(height: 30),

            // 🔹 Tombol aksi di bawah detail
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
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
            expedition.expeditionName,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dipimpin oleh : ${expedition.leaderName}',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                    color: color ?? const Color(0xFF2D3436),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
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
            'Anggaran Ekspedisi',
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
              Text('Total Anggaran:', style: GoogleFonts.poppins(fontSize: 14)),
              Text(
                '${expedition.currency} ${NumberFormat.currency(symbol: '', decimalDigits: 0).format(expedition.totalBudget)}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4A8273),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.grey),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Setelah Konversi (${expedition.targetCurrency})',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              Text(
                '${NumberFormat.currency(symbol: '', decimalDigits: 2).format(expedition.convertedBudget)} ${expedition.targetCurrency}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3436),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🔹 Tambahan tombol aksi (edit & hapus)
  Widget _buildActionButtons(BuildContext context) {
    final controller = context.read<ExpeditionController>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Tombol Edit
        ElevatedButton.icon(
          onPressed: () async {
            final updated = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditExpeditionPage(
                  expedition: expedition,
                ), // gunakan halaman edit
              ),
            );

            // Jika user berhasil mengedit, reload data
            if (updated == true && context.mounted) {
              CustomSnackbar.show(
                context,
                "Data berhasil diperbarui!",
                type: SnackbarType.success,
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE2EF6A),
            foregroundColor: const Color.fromARGB(255, 0, 0, 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 12.0,
            ),
          ),
          icon: const Icon(Icons.edit),
          label: const Text('Edit'),
        ),

        // Tombol Hapus
        ElevatedButton.icon(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Konfirmasi Hapus'),
                content: const Text(
                  'Apakah kamu yakin ingin menghapus ekspedisi ini?',
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
              await controller.deleteExpedition(expedition.expeditionId);
              if (context.mounted) {
                Navigator.pop(context); // kembali ke list
                CustomSnackbar.show(
                  context,
                  "Ekspedisi berhasil dihapus",
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
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 12.0,
            ),
          ),
          icon: const Icon(Icons.delete),
          label: const Text('Hapus'),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aktif':
        return Colors.green;
      case 'selesai':
        return Colors.blue;
      case 'akan datang':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
