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

class EditLogbookPage extends StatefulWidget {
  final LogbookModel logbook;

  const EditLogbookPage({super.key, required this.logbook});

  @override
  State<EditLogbookPage> createState() => _EditLogbookPageState();
}

class _EditLogbookPageState extends State<EditLogbookPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final titleCtrl = TextEditingController();
  final contentCtrl = TextEditingController();
  final obstacleCtrl = TextEditingController();
  final suggestionCtrl = TextEditingController();
  final expenseCtrl = TextEditingController();

  bool isLoading = false;
  bool isFetchingLocation = false;

  String expeditionCurrency = 'IDR';
  double remainingBudget = 0;

  String? locationName;
  double? latitude;
  double? longitude;
  double? elevation;
  String? weather;
  DateTime? dateTime;
  String selectedTimezone = 'Asia/Jakarta';
  List<String> imagePaths = [];

  final List<Map<String, String>> timezoneOptions = [
    {'name': 'WIB (Jakarta)', 'value': 'Asia/Jakarta'},
    {'name': 'WITA (Makassar)', 'value': 'Asia/Makassar'},
    {'name': 'WIT (Jayapura)', 'value': 'Asia/Jayapura'},
    {'name': 'UTC', 'value': 'UTC'},
  ];

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _initializeData();
  }

  void _initializeData() {
    final log = widget.logbook;

    titleCtrl.text = log.title;
    contentCtrl.text = log.content;
    obstacleCtrl.text = log.obstacle ?? '';
    suggestionCtrl.text = log.suggestion ?? '';
    expenseCtrl.text = log.dailyExpense.toStringAsFixed(0);
    imagePaths = List<String>.from(log.images);

    locationName = log.location;
    latitude = log.latitude;
    longitude = log.longitude;
    elevation = log.elevation;
    weather = log.weather;
    dateTime = log.date;
    remainingBudget = log.remainingBudget;
  }

  Future<void> _getCurrentLocation() async {
    setState(() => isFetchingLocation = true);
    final data = await LocationService.getCompleteLocationData();
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

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      for (final img in picked) {
        final file = File('${dir.path}/${img.name}');
        await file.writeAsBytes(await img.readAsBytes());
        imagePaths.add(file.path);
      }
      setState(() {});
    }
  }

  void _removeImage(int index) {
    setState(() => imagePaths.removeAt(index));
  }

  // ========== UPDATE LOGBOOK ==========
  Future<void> _updateLogbook() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final updatedLogbook = widget.logbook
        ..title = titleCtrl.text.trim()
        ..content = contentCtrl.text.trim()
        ..obstacle = obstacleCtrl.text.trim()
        ..suggestion = suggestionCtrl.text.trim()
        ..date = dateTime ?? DateTime.now()
        ..location = locationName ?? 'Unknown'
        ..latitude = latitude
        ..longitude = longitude
        ..elevation = elevation
        ..weather = weather
        ..images = imagePaths
        ..updatedAt = DateTime.now()
        ..dailyExpense =
            double.tryParse(expenseCtrl.text.replaceAll(',', '')) ?? 0.0;

      final controller = Provider.of<LogbookController>(context, listen: false);
      await controller.updateLogbook(updatedLogbook);

      if (mounted) {
        CustomSnackbar.show(
          context,
          'Logbook berhasil diperbarui!',
          type: SnackbarType.success,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      CustomSnackbar.show(
        context,
        'Gagal memperbarui logbook: $e',
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ========== UI ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A8273),
        elevation: 0,
        title: Text(
          'Edit Logbook',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Informasi Logbook'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: titleCtrl,
                label: 'Judul Logbook',
                hint: 'Contoh: Hari 2 - Perjalanan ke Pos 3',
                icon: Icons.title,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Judul harus diisi' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: contentCtrl,
                label: 'Isi Catatan',
                hint: 'Ceritakan pengalaman perjalanan...',
                icon: Icons.description,
                maxLines: 5,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Isi catatan harus diisi' : null,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Lokasi & Kondisi'),
              const SizedBox(height: 16),
              _buildLocationCard(),
              const SizedBox(height: 24),
              _buildSectionTitle('Pengeluaran'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: expenseCtrl,
                label: 'Pengeluaran Hari Ini',
                hint: '0',
                icon: Icons.account_balance_wallet,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                suffixText: expeditionCurrency,
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Kendala & Saran'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: obstacleCtrl,
                label: 'Kendala yang Dialami',
                hint: 'Contoh: Jalur licin, cuaca buruk...',
                icon: Icons.warning_amber,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: suggestionCtrl,
                label: 'Saran / Evaluasi',
                hint: 'Saran untuk perjalanan berikutnya...',
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
                  onPressed: isLoading ? null : _updateLogbook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A8273),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : Text(
                          'Perbarui Logbook',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== Widget Utility =====

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF2D3436),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
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
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3436),
          ),
        ),
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
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF4A8273), width: 2),
            ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          _buildLocationItem(Icons.location_on, 'Lokasi', locationName ?? '-',
              Colors.blue),
          const Divider(height: 24),
          _buildLocationItem(
              Icons.map,
              'Koordinat',
              '${latitude?.toStringAsFixed(5) ?? '-'}, ${longitude?.toStringAsFixed(5) ?? '-'}',
              Colors.blue),
          const Divider(height: 24),
          _buildLocationItem(Icons.cloud, 'Cuaca', weather ?? '-', Colors.orange),
          const Divider(height: 24),
          _buildLocationItem(Icons.terrain, 'Elevasi',
              elevation != null ? '${elevation!.toStringAsFixed(1)} mdpl' : '-',
              Colors.green),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _getCurrentLocation,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Perbarui Lokasi'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4A8273),
              side: const BorderSide(color: Color(0xFF4A8273)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationItem(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '$label: $value',
            style: GoogleFonts.poppins(fontSize: 14),
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
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF4A8273),
            side: const BorderSide(color: Color(0xFF4A8273)),
          ),
        ),
        if (imagePaths.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: imagePaths.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(imagePaths[index]),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}
