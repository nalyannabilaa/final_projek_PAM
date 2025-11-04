import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/expedition_model.dart';

class ExpeditionSelectorWidget extends StatelessWidget {
  final List<ExpeditionModel> expeditions;
  final ExpeditionModel? selectedExpedition;
  final Function(ExpeditionModel) onExpeditionSelected;

  const ExpeditionSelectorWidget({
    super.key,
    required this.expeditions,
    required this.selectedExpedition,
    required this.onExpeditionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildFullWidthDropdown(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4A8273).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.explore, color: Color(0xFF4A8273), size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          'Pilih Ekspedisi Aktif',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3436),
          ),
        ),
        const Spacer(),
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
                '${expeditions.length} Aktif',
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
    );
  }

  Widget _buildFullWidthDropdown(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _showFullWidthMenu(context, constraints.maxWidth),
          child: InputDecorator(
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF4A8273), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedExpedition?.expeditionName ??
                        'Pilih ekspedisi untuk melihat logbook...',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: selectedExpedition == null
                          ? Colors.grey[400]
                          : const Color(0xFF2D3436),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Color(0xFF4A8273)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFullWidthMenu(BuildContext context, double fieldWidth) async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset offset = button.localToGlobal(Offset.zero, ancestor: overlay);

    final RelativeRect position = RelativeRect.fromLTRB(
      offset.dx,                    // kiri = kiri field
      offset.dy + button.size.height, // atas = bawah field
      offset.dx + fieldWidth,       // kanan = kanan field
      overlay.size.height,          // bawah = bawah layar
    );

    final selected = await showMenu<ExpeditionModel>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      color: Colors.white,
      constraints: BoxConstraints(
        maxHeight: 300,
        maxWidth: fieldWidth, // Lebar penuh sesuai field
        minWidth: fieldWidth,
      ),
      items: expeditions.map((expedition) {
        return PopupMenuItem<ExpeditionModel>(
          value: expedition,
          padding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: _buildDropdownItem(expedition),
          ),
        );
      }).toList(),
    );

    if (selected != null) {
      onExpeditionSelected(selected);
    }
  }

  Widget _buildDropdownItem(ExpeditionModel expedition) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          expedition.expeditionName,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3436),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Icon(Icons.calendar_today, size: 11, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${DateFormat('dd MMM', 'id_ID').format(expedition.startDate)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(expedition.endDate)}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (expedition != expeditions.last)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),
      ],
    );
  }
}