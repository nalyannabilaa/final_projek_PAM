import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/expedition_controller.dart';
import '../../models/expedition_model.dart';
import '../../services/session_manager.dart';
import 'convert_currency.dart';
import '../../widgets/custom_snackbar.dart';

class AddExpeditionPage extends StatefulWidget {
  final int leaderId;

  const AddExpeditionPage({super.key, required this.leaderId});

  @override
  State<AddExpeditionPage> createState() => _AddExpeditionPageState();
}

class _AddExpeditionPageState extends State<AddExpeditionPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();

  // Date
  DateTime? _startDate;
  DateTime? _endDate;

  // Currency & conversion
  double? _convertedResult;
  String _selectedCurrency = 'IDR';
  String _targetCurrency = 'USD';

  // Dropdowns
  bool _isLoading = false;
  final List<String> _currencyOptions = ['IDR', 'USD', 'EUR', 'SGD', 'MYR'];

  @override
  void initState() {
    super.initState();
    _budgetController.addListener(updateConversion);
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
      initialDate: DateTime.now(),
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

  // 🔹 Simpan ekspedisi baru
  Future<void> _saveExpedition() async {
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

    try {
      final controller = context.read<ExpeditionController>();
      final session = await SessionManager.getUserSession();
      final leaderId = session?['leaderId'] ?? 1;
      final leaderName = session?['username'] ?? 'Unknown';

      // Tentukan status otomatis berdasarkan tanggal
      final now = DateTime.now();
      String autoStatus;
      if (now.isBefore(_startDate!)) {
        autoStatus = 'akan datang';
      } else if (now.isAfter(_endDate!)) {
        autoStatus = 'selesai';
      } else {
        autoStatus = 'aktif';
      }

      final newId = controller.expeditions.isEmpty
          ? 1
          : controller.expeditions
                    .map((e) => e.expeditionId)
                    .reduce((a, b) => a > b ? a : b) +
                1;

      final totalBudget = double.parse(
        _budgetController.text.replaceAll(',', ''),
      );
      final converted = ConvertCurrency.convert(
        totalBudget,
        _selectedCurrency,
        _targetCurrency,
      );

      final newExpedition = ExpeditionModel(
        expeditionId: newId,
        leaderId: widget.leaderId,
        leaderName: leaderName,
        expeditionName: _nameController.text.trim(),
        location: _locationController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
        status: autoStatus,
        totalBudget: totalBudget,
        currency: _selectedCurrency,
        convertedBudget: converted,
        targetCurrency: _targetCurrency,
      );

      await controller.addExpedition(newExpedition);
      await controller.loadExpeditions(widget.leaderId);

      if (mounted) {
        CustomSnackbar.show(
          context,
          "Ekspedisi berhasil ditambahkan (${autoStatus.toUpperCase()})",
          type: SnackbarType.success,
        );
        await Future.delayed(const Duration(milliseconds: 600));
        Navigator.pop(context);
      }
    } catch (e) {
      CustomSnackbar.show(
        context,
        "Gagal menambah ekspedisi: $e",
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔹 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A8273),
        title: Text(
          'Tambah Ekspedisi',
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
              _buildTextField(
                controller: _nameController,
                colorcard: const Color.fromARGB(255, 255, 255, 255),
                label: 'Nama Ekspedisi',
                hint: 'Contoh: Pendakian Gunung Semeru',
                icon: Icons.hiking,
                validator: (v) => v == null || v.isEmpty
                    ? 'Nama ekspedisi harus diisi'
                    : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _locationController,
                colorcard: const Color.fromARGB(255, 255, 255, 255),
                label: 'Lokasi',
                hint: 'Contoh: Jawa Timur',
                icon: Icons.location_on,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Lokasi harus diisi' : null,
              ),
              const SizedBox(height: 24),
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
              const SizedBox(height: 24),
              if (_startDate != null && _endDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: _buildAutoStatusPreview(),
                ),

              const SizedBox(height: 24),
              _buildTextField(
                controller: _budgetController,
                colorcard: const Color.fromARGB(255, 255, 255, 255),
                label: 'Total Anggaran',
                hint: '0',
                icon: Icons.account_balance_wallet,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) =>
                    v == null || v.isEmpty ? 'Anggaran harus diisi' : null,
              ),
              const SizedBox(height: 16),
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
              if (_convertedResult != null)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '💱 ${_budgetController.text} $_selectedCurrency = '
                    '${_convertedResult!.toStringAsFixed(2)} $_targetCurrency',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveExpedition,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A8273),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Simpan Ekspedisi',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white,
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

  // 🔹 Reuse Widgets
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color colorcard,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
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
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF4A8273)),
            filled: true,
            fillColor: colorcard,
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
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF4A8273),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  date != null
                      ? DateFormat('dd MMM yyyy').format(date)
                      : 'Pilih tanggal',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: date != null
                        ? const Color(0xFF2D3436)
                        : Colors.grey[400],
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
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(218, 255, 255, 255),
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
                vertical: 12,
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
