import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/expedition_controller.dart';
import '../../models/expedition_model.dart';
import 'convert_currency.dart';
import '../../widgets/custom_snackbar.dart';

class EditExpeditionPage extends StatefulWidget {
  final ExpeditionModel expedition;

  const EditExpeditionPage({super.key, required this.expedition});

  @override
  State<EditExpeditionPage> createState() => _EditExpeditionPageState();
}

class _EditExpeditionPageState extends State<EditExpeditionPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _budgetController;

  // Date
  DateTime? _startDate;
  DateTime? _endDate;

  // Currency & dropdowns
  late String _selectedCurrency;
  late String _targetCurrency;

  double? _convertedResult;
  bool _isLoading = false;
  final List<String> _currencyOptions = ['IDR', 'USD', 'EUR', 'SGD', 'MYR'];

  @override
  void initState() {
    super.initState();

    // Inisialisasi dengan data lama
    final expedition = widget.expedition;

    _nameController = TextEditingController(text: expedition.expeditionName);
    _locationController = TextEditingController(text: expedition.location);
    _budgetController = TextEditingController(
      text: expedition.totalBudget.toString(),
    );

    _startDate = expedition.startDate;
    _endDate = expedition.endDate;
    _selectedCurrency = expedition.currency;
    _targetCurrency = expedition.targetCurrency;

    _budgetController.addListener(updateConversion);
    updateConversion();
  }

  @override
  void dispose() {
    _budgetController.removeListener(updateConversion);
    _budgetController.dispose();
    super.dispose();
  }

  // 🔹 Update konversi realtime
  void updateConversion() {
    if (_budgetController.text.isEmpty) {
      setState(() => _convertedResult = null);
      return;
    }

    final double amount =
        double.tryParse(_budgetController.text.replaceAll(',', '')) ?? 0;
    final result = ConvertCurrency.convert(
      amount,
      _selectedCurrency,
      _targetCurrency,
    );
    setState(() => _convertedResult = result);
  }

  // 🔹 Date picker
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF4A8273),
            onPrimary: Colors.white,
            onSurface: Color(0xFF2D3436),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // 🔹 Simpan perubahan ekspedisi
  Future<void> _updateExpedition() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      CustomSnackbar.show(
        context,
        "Pilih tanggal mulai dan selesai ekspedisi",
        type: SnackbarType.error,
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      CustomSnackbar.show(
        context,
        "Tanggal selesai harus setelah tanggal mulai",
        type: SnackbarType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

          final now = DateTime.now();
      String autoStatus;
      if (now.isBefore(_startDate!)) {
        autoStatus = 'akan datang';
      } else if (now.isAfter(_endDate!)) {
        autoStatus = 'selesai';
      } else {
        autoStatus = 'aktif';
      }

    try {
      final controller = context.read<ExpeditionController>();

      final updatedExpedition = ExpeditionModel(
        expeditionId: widget.expedition.expeditionId,
        leaderId: widget.expedition.leaderId,
        leaderName: widget.expedition.leaderName,
        expeditionName: _nameController.text.trim(),
        location: _locationController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
        status: autoStatus,
        totalBudget: double.parse(_budgetController.text.replaceAll(',', '')),
        currency: _selectedCurrency,
        convertedBudget: _convertedResult ?? 0,
        targetCurrency: _targetCurrency,
      );

      await controller.updateExpedition(updatedExpedition);

      if (mounted) {
        CustomSnackbar.show(
          context,
          "Data berhasil diperbarui!",
          type: SnackbarType.success,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      CustomSnackbar.show(
        context,
        "Gagal memperbarui ekspedisi: $e",
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔹 Build UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A8273),
        title: Text(
          'Edit Ekspedisi',
          style: GoogleFonts.poppins(
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
              _buildTextField(
                controller: _nameController,
                label: 'Nama Ekspedisi',
                hint: 'Masukkan nama ekspedisi',
                icon: Icons.hiking,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _locationController,
                label: 'Lokasi',
                hint: 'Masukkan lokasi ekspedisi',
                icon: Icons.location_on,
              ),
              const SizedBox(height: 16),

              // 📅 Tanggal
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      label: 'Tanggal Mulai',
                      date: _startDate,
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateField(
                      label: 'Tanggal Selesai',
                      date: _endDate,
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_startDate != null && _endDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: _buildAutoStatusPreview(),
                ),
              const SizedBox(height: 16),

              // 💰 Anggaran
              _buildTextField(
                controller: _budgetController,
                label: 'Total Anggaran',
                hint: '0',
                icon: Icons.account_balance_wallet,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),

              // Mata uang
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      label: 'Mata Uang Asal',
                      value: _selectedCurrency,
                      items: _currencyOptions,
                      icon: Icons.monetization_on,
                      onChanged: (v) {
                        setState(() => _selectedCurrency = v!);
                        updateConversion();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdownField(
                      label: 'Konversi Ke',
                      value: _targetCurrency,
                      items: _currencyOptions,
                      icon: Icons.swap_horiz,
                      onChanged: (v) {
                        setState(() => _targetCurrency = v!);
                        updateConversion();
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              if (_convertedResult != null)
                Text(
                  '💱 Hasil Konversi: ${_convertedResult!.toStringAsFixed(2)} $_targetCurrency',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF4A8273),
                  ),
                ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateExpedition,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A8273),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Simpan Perubahan',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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

  // 🔹 Reusable Widgets
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: (v) => v == null || v.isEmpty ? 'Harus diisi' : null,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF4A8273)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF4A8273),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  date != null
                      ? DateFormat('dd MMM yyyy').format(date)
                      : 'Pilih tanggal',
                  style: GoogleFonts.poppins(
                    color: date != null ? Colors.black : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF4A8273)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }

    // 🔹 Preview status otomatis
Widget _buildAutoStatusPreview() {
  if (_startDate == null || _endDate == null) return const SizedBox();

  final now = DateTime.now();
  String statusText;
  Color statusColor;

  if (now.isBefore(_startDate!)) {
    statusText = 'Status Otomatis: Akan Datang';
    statusColor = Colors.blueAccent;
  } else if (now.isAfter(_endDate!)) {
    statusText = 'Status Otomatis: Selesai';
    statusColor = Colors.grey;
  } else {
    statusText = 'Status Otomatis: Aktif';
    statusColor = Colors.green;
  }

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: statusColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(Icons.flag, color: statusColor),
        const SizedBox(width: 8),
        Text(
          statusText,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: statusColor,
          ),
        ),
      ],
    ),
  );
}
}
