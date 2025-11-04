import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/expedition_model.dart';

class ExpeditionInfoCardWidget extends StatelessWidget {
  final ExpeditionModel expedition;
  final int logbookCount;

  const ExpeditionInfoCardWidget({
    super.key,
    required this.expedition,
    required this.logbookCount,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysRemaining = expedition.endDate.difference(now).inDays;
    final totalDays = expedition.endDate.difference(expedition.startDate).inDays;
    final daysElapsed = now.difference(expedition.startDate).inDays;
    final progress = totalDays > 0 
      ? (daysElapsed / totalDays).clamp(0.0, 1.0) 
      : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A8273), Color(0xFF6FA88E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A8273).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(daysRemaining),
          const SizedBox(height: 14),
          _buildExpeditionName(),
          const SizedBox(height: 8),
          _buildLocation(),
          const SizedBox(height: 14),
          _buildProgressSection(progress, daysElapsed, totalDays),
        ],
      ),
    );
  }

  Widget _buildHeader(int daysRemaining) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.circle, size: 8, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                'AKTIF',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 14,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                '$daysRemaining hari lagi',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpeditionName() {
    return Text(
      expedition.expeditionName,
      style: GoogleFonts.poppins(
        fontSize: 19,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        height: 1.2,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildLocation() {
    return Row(
      children: [
        const Icon(
          Icons.location_on,
          size: 15,
          color: Colors.white70,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            expedition.location,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white70,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(double progress, int daysElapsed, int totalDays) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress Ekspedisi',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Hari ke-$daysElapsed dari $totalDays hari',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.white60,
              ),
            ),
            Text(
              '$logbookCount logbook',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.white60,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}