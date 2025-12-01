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

    final logbooks = logbookController.logbooks;

    // 🔥 FIX: Prioritaskan ekspedisi yang dipilih user
    ExpeditionModel? displayExpedition = logbookController.selectedExpedition;

    // 🔥 Fallback jika tidak ada yang dipilih
    if (displayExpedition == null) {
      final expeditions = expeditionController.expeditions;
      
      try {
        displayExpedition =
            expeditions.firstWhere((e) => e.status.toLowerCase() == 'aktif');
      } catch (_) {
        try {
          displayExpedition = expeditions.firstWhere(
              (e) => e.status.toLowerCase() == 'akan datang');
        } catch (_) {
          displayExpedition = null;
        }
      }
    }

    // 🔥 Tentukan label berdasarkan status ekspedisi yang ditampilkan
    String cardTitle;
    if (displayExpedition == null) {
      cardTitle = 'Belum Ada Ekspedisi';
    } else if (displayExpedition.status.toLowerCase() == 'aktif') {
      cardTitle = 'Ekspedisi Aktif';
    } else if (displayExpedition.status.toLowerCase() == 'akan datang') {
      cardTitle = 'Ekspedisi Terdekat';
    } else if (displayExpedition.status.toLowerCase() == 'selesai') {
      cardTitle = 'Ekspedisi Selesai';
    } else {
      cardTitle = 'Ekspedisi Terpilih';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                cardTitle,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // 🔥 Indikator jika ada ekspedisi yang dipilih
              if (logbookController.selectedExpedition != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A8273).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: Color(0xFF4A8273)),
                      const SizedBox(width: 4),
                      Text(
                        'Dipilih',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4A8273),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
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

  String? _getLatestLogbookImage(
      ExpeditionModel expedition, List<LogbookModel> logbooks) {
    final relatedLogs = logbooks
        .where((log) => log.expeditionId == expedition.expeditionId.toString())
        .toList();

    if (relatedLogs.isEmpty) return null;

    relatedLogs.sort((a, b) => b.date.compareTo(a.date));

    if (relatedLogs.first.images.isNotEmpty) {
      return relatedLogs.first.images.first;
    }

    return null;
  }

  Widget _buildExpeditionCard(
    BuildContext context,
    ExpeditionModel expedition,
    List<LogbookModel> logbooks,
  ) {
    final isActive = expedition.status.toLowerCase() == 'aktif';
    final isUpcoming = expedition.status.toLowerCase() == 'akan datang';
    final isCompleted = expedition.status.toLowerCase() == 'selesai';
    
    // 🔥 Gradient berdasarkan status
    final gradient = isActive
        ? const [Color(0xFFE3DE61), Color(0xFF5DA290)]
        : isUpcoming
            ? const [Color(0xFFFFA500), Color(0xFFFF6347)]
            : isCompleted
                ? const [Color(0xFF6C757D), Color(0xFF495057)]
                : const [Color(0xFFE3DE61), Color(0xFF5DA290)];
    
    const textColor = Colors.white;

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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          expedition.expeditionName,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      // 🔥 Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          expedition.status.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
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
                  // 🔥 Info waktu yang lebih dinamis
                  Text(
                    isActive
                        ? 'Sisa $daysRemaining hari'
                        : isUpcoming
                            ? 'Mulai dalam $daysUntilStart hari'
                            : isCompleted
                                ? 'Telah selesai'
                                : 'Status: ${expedition.status}',
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