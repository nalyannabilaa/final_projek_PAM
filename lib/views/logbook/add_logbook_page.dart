import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import '../../controllers/logbook_controller.dart';
import '../../models/logbook_model.dart';
import '../../widgets/custom_snackbar.dart';
import '../../services/location_service.dart';
import '../../models/expedition_model.dart';
import '../../services/session_manager.dart';
import '../../utils/notification_helper.dart';

class AddLogbookPage extends StatefulWidget {
  final String expeditionId;
  final String username;

  const AddLogbookPage({
    super.key,
    required this.expeditionId,
    required this.username,
  });

  @override
  State<AddLogbookPage> createState() => _AddLogbookPageState();
}

class _AddLogbookPageState extends State<AddLogbookPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final titleCtrl = TextEditingController();
  final contentCtrl = TextEditingController();
  final obstacleCtrl = TextEditingController();
  final suggestionCtrl = TextEditingController();
  final expenseCtrl = TextEditingController();

  // State
  bool isLoading = false;
  bool isFetchingLocation = true;
  String? locationName;
  double? latitude;
  double? longitude;
  double? elevation;
  String? weather;
  DateTime? dateTime;
  String expeditionName = '';
  String expeditionCurrency = 'IDR';
  double totalBudget = 0;
  double remainingBudget = 0;
  String selectedTimezone = 'Asia/Jakarta';
  List<String> imagePaths = [];

  final List<Map<String, String>> timezoneOptions = [
    {'name': 'WIB (Jakarta)', 'value': 'Asia/Jakarta'},
    {'name': 'WITA (Makassar)', 'value': 'Asia/Makassar'},
    {'name': 'WIT (Jayapura)', 'value': 'Asia/Jayapura'},
    {'name': 'UTC', 'value': 'UTC'},
    {'name': 'GMT', 'value': 'GMT'},
  ];

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _loadInitialData();
    _getCurrentLocation();
  }

  Future<void> _loadInitialData() async {
    final logbookController = context.read<LogbookController>();
    final selectedExpedition = logbookController.selectedExpedition;

    if (selectedExpedition == null) {
      if (mounted) {
        CustomSnackbar.show(
          context,
          'Pilih ekspedisi aktif terlebih dahulu',
          type: SnackbarType.error,
        );
        Navigator.pop(context);
      }
      return;
    }

    setState(() {
      expeditionName = selectedExpedition.expeditionName;
      expeditionCurrency = selectedExpedition.targetCurrency;
      totalBudget = selectedExpedition.convertedBudget;
      remainingBudget = logbookController.remainingBudget;
    });
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    contentCtrl.dispose();
    obstacleCtrl.dispose();
    suggestionCtrl.dispose();
    expenseCtrl.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    final data = await LocationService.getCompleteLocationData();
    if (!mounted) return;

    setState(() {
      latitude = data['latitude'];
      longitude = data['longitude'];
      locationName = data['locationName'];
      weather = data['weather'];
      elevation = data['elevation'];
      selectedTimezone = data['timezone'] ?? 'Asia/Jakarta';
      dateTime = data['dateTime'];
      isFetchingLocation = false;
    });
  }

  void _updateDateTime() {
    dateTime = LocationService.getTimeByTimezone(selectedTimezone);
    setState(() {});
  }

  // ========== IMAGE PICKER ==========
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty) return;

    final dir = await getApplicationDocumentsDirectory();
    final newPaths = <String>[];

    for (final img in picked) {
      final file = File('${dir.path}/${img.name}');
      await file.writeAsBytes(await img.readAsBytes());
      newPaths.add(file.path);
    }

    setState(() => imagePaths.addAll(newPaths));
  }

  void _removeImage(int index) {
    setState(() => imagePaths.removeAt(index));
  }

  // ========== SAVE LOGBOOK ==========
  Future<void> _saveLogbook() async {
    if (!_formKey.currentState!.validate()) return;
    if (latitude == null || longitude == null) {
      CustomSnackbar.show(context, 'Tunggu lokasi selesai dimuat', type: SnackbarType.error);
      return;
    }

    setState(() => isLoading = true);

    try {
      final logbookController = context.read<LogbookController>();
      final selectedExp = logbookController.selectedExpedition;
      if (selectedExp == null) {
        CustomSnackbar.show(context, 'Ekspedisi tidak ditemukan', type: SnackbarType.error);
        return;
      }

      final expense = double.tryParse(expenseCtrl.text.replaceAll(',', '')) ?? 0.0;

      final logbook = LogbookModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        expeditionId: selectedExp.expeditionId.toString(),
        title: titleCtrl.text.trim(),
        content: contentCtrl.text.trim(),
        obstacle: obstacleCtrl.text.trim(),
        suggestion: suggestionCtrl.text.trim(),
        date: dateTime ?? DateTime.now(),
        location: locationName ?? 'Unknown',
        latitude: latitude,
        longitude: longitude,
        elevation: elevation,
        weather: weather,
        images: imagePaths,
        username: widget.username,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dailyExpense: expense,
        remainingBudget: remainingBudget - expense,
      );

      await logbookController.addLogbook(logbook);

      // Notifikasi sisa anggaran
      final formatted = NumberFormat.currency(
        locale: 'id_ID',
        symbol: expeditionCurrency == 'IDR' ? 'Rp' : '$expeditionCurrency ',
        decimalDigits: 2,
      ).format(logbookController.remainingBudget);

      await NotificationHelper.showNotification(
        title: 'Sisa Anggaran $expeditionName',
        body: 'Anggaran tersisa: $formatted',
      );

      if (mounted) {
        CustomSnackbar.show(context, 'Logbook berhasil ditambahkan!', type: SnackbarType.success);
        await Future.delayed(const Duration(milliseconds: 600));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(context, 'Gagal menyimpan: $e', type: SnackbarType.error);
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A8273),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text('Tambah Logbook Harian', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Informasi Logbook'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3DE61).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE3DE61).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ekspedisi:', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])),
                    const SizedBox(height: 4),
                    Text(expeditionName, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF2D3436))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: titleCtrl,
                label: 'Judul Logbook',
                hint: 'Contoh: Hari 2 - Perjalanan ke Pos 3',
                colorcard: const Color.fromARGB(255, 255, 255, 255),
                icon: Icons.title,
                validator: (v) => v?.isEmpty ?? true ? 'Judul harus diisi' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: contentCtrl,
                label: 'Isi Catatan',
                hint: 'Ceritakan pengalaman perjalanan hari ini...',
                colorcard: Colors.white,
                icon: Icons.description,
                maxLines: 5,
                validator: (v) => v?.isEmpty ?? true ? 'Isi catatan harus diisi' : null,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Lokasi & Kondisi'),
              const SizedBox(height: 16),
              _buildLocationCard(),
              const SizedBox(height: 16),
              _buildTimezoneSelector(),
              const SizedBox(height: 24),
              _buildSectionTitle('Pengeluaran'),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: expenseCtrl,
                    label: 'Pengeluaran Hari Ini',
                    hint: '0',
                    colorcard: Colors.white,
                    icon: Icons.account_balance_wallet,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    suffixText: expeditionCurrency,
                    validator: (v) => v?.isEmpty ?? true ? 'Masukkan jumlah pengeluaran' : null,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Sisa Anggaran:', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])),
                      Text(
                        NumberFormat.currency(locale: 'id_ID', symbol: '$expeditionCurrency ').format(remainingBudget),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: remainingBudget > 0 ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Kendala & Saran'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: obstacleCtrl,
                label: 'Kendala yang Dialami',
                hint: 'Contoh: Jalur licin, cuaca buruk...',
                colorcard: const Color.fromARGB(255, 255, 255, 255),
                icon: Icons.warning_amber,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: suggestionCtrl,
                label: 'Saran / Evaluasi',
                hint: 'Saran untuk perjalanan berikutnya...',
                colorcard: Colors.white,
                icon: Icons.lightbulb_outline,
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Dokumentasi'),
              const SizedBox(height: 16),
              _buildImageSection(),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _saveLogbook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A8273),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Simpan Logbook', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== WIDGETS (TIDAK BERUBAH) ==========
  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436)));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Color colorcard,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? suffixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF2D3436))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: const Color(0xFF4A8273)),
            suffixText: suffixText,
            filled: true,
            fillColor: colorcard,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4A8273), width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
          ),
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          if (isFetchingLocation)
            Column(children: [
              const CircularProgressIndicator(color: Color(0xFF4A8273)),
              const SizedBox(height: 12),
              Text('Mengambil lokasi...', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
            ])
          else ...[
            _buildLocationItem(Icons.location_on, 'Lokasi', locationName ?? 'Unknown', Colors.blue),
            const Divider(height: 24),
            _buildLocationItem(Icons.map, 'Koordinat', '${latitude?.toStringAsFixed(5) ?? '-'}°, ${longitude?.toStringAsFixed(5) ?? '-'}°', Colors.blue),
            const Divider(height: 24),
            _buildLocationItem(Icons.cloud, 'Cuaca', weather ?? '-', Colors.orange),
            const Divider(height: 24),
            _buildLocationItem(Icons.terrain, 'Elevasi', elevation != null ? '${elevation!.toStringAsFixed(1)} mdpl' : '-', Colors.green),
            const Divider(height: 24),
            _buildLocationItem(Icons.access_time, 'Waktu', dateTime != null ? DateFormat('dd MMM yyyy, HH:mm').format(dateTime!) : '-', Colors.purple),
            Row(children: [Expanded(child: Text(selectedTimezone.replaceAll('_', ' '), style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic)))]),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text('Perbarui Lokasi', style: GoogleFonts.poppins(fontSize: 14)),
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF4A8273), side: const BorderSide(color: Color(0xFF4A8273)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationItem(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 2),
              Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF2D3436)), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_photo_alternate),
          label: Text('Tambah Foto', style: GoogleFonts.poppins(fontSize: 14)),
          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF4A8273), side: const BorderSide(color: Color(0xFF4A8273)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
        if (imagePaths.isNotEmpty) ...[
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: imagePaths.length,
            itemBuilder: (context, index) => Stack(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(imagePaths[index]), width: double.infinity, height: double.infinity, fit: BoxFit.cover)),
                Positioned(top: 4, right: 4, child: GestureDetector(onTap: () => _removeImage(index), child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 16)))),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimezoneSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Zona Waktu', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF2D3436))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: const Color.fromARGB(255, 255, 255, 255), 
          borderRadius: BorderRadius.circular(12), 
          border: Border.all(color: Colors.grey[300]!)),
          child: DropdownButtonFormField<String>(
            value: selectedTimezone,
            items: timezoneOptions.map((tz) => DropdownMenuItem(value: tz['value'], child: Text(tz['name']!, style: GoogleFonts.poppins(fontSize: 14)))).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedTimezone = value;
                  _updateDateTime();
                });
              }
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.schedule, color: Color(0xFF4A8273)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            dropdownColor: Colors.white,
            icon: const Icon(Icons.arrow_drop_down),
          ),
        ),
      ],
    );
  }
}