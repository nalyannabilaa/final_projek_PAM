import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/expedition_controller.dart';
import '../../controllers/logbook_controller.dart';
import '../../models/expedition_model.dart';
import '../../models/logbook_model.dart';
import '../expedition/expedition_detail_page.dart';

class ExpeditionCardSection extends StatelessWidget {
  const ExpeditionCardSection({super.key});

  @override
  Widget build(BuildContext context) {
    final expeditionController = context.watch<ExpeditionController>();
    final logbookController = context.watch<LogbookController>();

    final expeditions = expeditionController.expeditions;
    final logbooks = logbookController.logbooks;

    ExpeditionModel? activeExpedition;
    ExpeditionModel? upcomingExpedition;

    try {
      activeExpedition =
          expeditions.firstWhere((e) => e.status.toLowerCase() == 'aktif');
    } catch (_) {
      activeExpedition = null;
    }

    try {
      upcomingExpedition =
          expeditions.firstWhere((e) => e.status.toLowerCase() == 'akan datang');
    } catch (_) {
      upcomingExpedition = null;
    }

    final displayExpedition = activeExpedition ?? upcomingExpedition;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            activeExpedition != null
                ? 'Ekspedisi Aktif'
                : upcomingExpedition != null
                    ? 'Ekspedisi Terdekat'
                    : 'Belum Ada Ekspedisi',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (displayExpedition != null)
            _buildExpeditionCard(context, displayExpedition, logbooks)
          else
            _buildNoExpeditionCard(),
        ],
      ),
    );
  }

  /// 🔹 Ambil gambar terbaru dari logbook ekspedisi
  String? _getLatestLogbookImage(
      ExpeditionModel expedition, List<LogbookModel> logbooks) {
    final relatedLogs = logbooks
        .where((log) => log.expeditionId == expedition.expeditionId.toString())
        .toList();

    if (relatedLogs.isEmpty) return null;

    relatedLogs.sort((a, b) => b.date.compareTo(a.date));

    if (relatedLogs.first.images.isNotEmpty) {
      return relatedLogs.first.images.first; // bisa file path
    }

    return null;
  }

  Widget _buildExpeditionCard(
    BuildContext context,
    ExpeditionModel expedition,
    List<LogbookModel> logbooks,
  ) {
    final isActive = expedition.status.toLowerCase() == 'aktif';
    final gradient = isActive
        ? const [Color(0xFFE3DE61), Color(0xFF5DA290)]
        : [Color(0xFFE3DE61), Color(0xFF5DA290)];
    final textColor = isActive ? Colors.white : Colors.white;

    final imagePath = _getLatestLogbookImage(expedition, logbooks);
    final now = DateTime.now();
    final daysRemaining = expedition.endDate.difference(now).inDays;
    final daysUntilStart = expedition.startDate.difference(now).inDays;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExpeditionDetailPage(expedition: expedition),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: _buildExpeditionImage(imagePath),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expedition.expeditionName,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          color: textColor.withOpacity(0.8), size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          expedition.location,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isActive
                        ? 'Sisa $daysRemaining hari'
                        : 'Mulai dalam $daysUntilStart hari',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: textColor.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('d MMM y').format(expedition.startDate)} - ${DateFormat('d MMM y').format(expedition.endDate)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: textColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpeditionImage(String? path) {
    if (path == null) {
      return _fallbackImage();
    }

    final isNetwork = path.startsWith('http');
    if (isNetwork) {
      return Image.network(
        path,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackImage(),
      );
    } else {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackImage(),
        );
      } else {
        return _fallbackImage();
      }
    }
  }

  Widget _fallbackImage() {
    return Image.network(
      'https://static.vecteezy.com/system/resources/previews/009/169/498/non_2x/sunset-landscape-over-mountains-with-a-traveler-standing-on-the-top-of-hill-vector.jpg',
      height: 150,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  Widget _buildNoExpeditionCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.hiking, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            'Belum Ada Ekspedisi',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Mulai rencanakan petualanganmu!',
            style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }
}
