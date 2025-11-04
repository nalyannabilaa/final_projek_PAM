import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/logbook_model.dart';
import '/../views/logbook/logbook_detail_page.dart';

class LogbookList extends StatelessWidget {
  final List<LogbookModel> logbooks;

  const LogbookList({super.key, required this.logbooks});

  @override
  Widget build(BuildContext context) {
    if (logbooks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(60),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFBEDAD3).withOpacity(0.3),
            border: Border.all(color: const Color(0xFF4A8273).withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.book_outlined,
                size: 48,
                color: const Color(0xFF4A8273).withOpacity(0.6),
              ),
              const SizedBox(height: 12),
              Text(
                'Belum ada logbook',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: const Color(0xFF353533),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mulai catat perjalanan Anda',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: logbooks.length,
      itemBuilder: (context, index) {
        final log = logbooks[index];
        return GestureDetector(
          onTap: () {
            // Navigasi ke halaman detail logbook
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LogbookDetailPage(logbook: log),
              ),
            );
          },
          child: _buildLogbookCard(log),
        );
      },
    );
  }

  Widget _buildLogbookCard(LogbookModel log) {
    final formattedDate = DateFormat(
      'EEE, dd MMM yyyy',
      'id_ID',
    ).format(log.date);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDFECE9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === Judul & Status ===
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  log.title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // === Tanggal ===
          Text(
            formattedDate,
            style: GoogleFonts.poppins(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 4),

          // === Lokasi ===
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF4A8273), size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  log.location,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[800],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // === Konten Singkat ===
          Text(
            log.shortContent,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[800]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),
          const Divider(thickness: 0.5, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 6),

          // === Cuaca dan Koordinat ===
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Cuaca
              Row(
                children: [
                  const Icon(
                    Icons.wb_sunny_outlined,
                    size: 18,
                    color: Color(0xFF4A8273),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    log.weather ?? "Tidak diketahui",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),

              // Koordinat
              Row(
                children: [
                  const Icon(
                    Icons.map_outlined,
                    size: 18,
                    color: Color(0xFF4A8273),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatCoordinates(log.latitude, log.longitude),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Format koordinat agar ringkas
  String _formatCoordinates(double? lat, double? lon) {
    if (lat == null || lon == null) return "-";
    return "${lat.toStringAsFixed(3)}, ${lon.toStringAsFixed(3)}";
  }
}
