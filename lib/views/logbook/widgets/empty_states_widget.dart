import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmptyStatesWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;
  final bool showLoading;

  const EmptyStatesWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
    this.showLoading = false,
  });

  // Named constructors untuk berbagai state
  const EmptyStatesWidget.loading()
      : icon = Icons.refresh,
        title = 'Memuat ekspedisi...',
        subtitle = '',
        iconColor = const Color(0xFF4A8273),
        showLoading = true;

  const EmptyStatesWidget.noActiveExpedition()
      : icon = Icons.explore_off,
        title = 'Tidak Ada Ekspedisi Aktif',
        subtitle = 'Mulai ekspedisi baru untuk\nmenambahkan logbook harian',
        iconColor = null,
        showLoading = false;

  const EmptyStatesWidget.selectExpedition()
      : icon = Icons.touch_app,
        title = 'Pilih Ekspedisi',
        subtitle = 'Pilih ekspedisi dari dropdown di atas\nuntuk melihat logbook harian',
        iconColor = const Color(0xFF4A8273),
        showLoading = false;

  const EmptyStatesWidget.noLogbook()
      : icon = Icons.book_outlined,
        title = 'Belum Ada Logbook',
        subtitle = 'Tekan tombol + di bawah untuk\nmenambahkan logbook pertama',
        iconColor = null,
        showLoading = false;

  @override
  Widget build(BuildContext context) {
    if (showLoading) {
      return _buildLoadingState();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIconContainer(),
            const SizedBox(height: 16),
            _buildTitle(),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildSubtitle(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF4A8273),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconContainer() {
    final effectiveIconColor = iconColor ?? Colors.grey[400];
    final backgroundColor = iconColor != null 
        ? iconColor!.withOpacity(0.1) 
        : Colors.grey[200];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 50,
        color: effectiveIconColor?.withOpacity(0.6),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.grey[700],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle() {
    return Text(
      subtitle,
      style: GoogleFonts.poppins(
        fontSize: 13,
        color: Colors.grey[500],
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }
}