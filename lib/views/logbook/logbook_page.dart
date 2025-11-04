import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import '../../controllers/logbook_controller.dart';
import '../../models/expedition_model.dart';
import '../../services/session_manager.dart';
import '../logbook/logbook_list.dart';
import '../logbook/add_logbook_page.dart';
import 'widgets/expedition_selector_widget.dart';
import 'widgets/expedition_info_card_widget.dart';
import 'widgets/empty_states_widget.dart';

class LogbookPage extends StatefulWidget {
  const LogbookPage({super.key});

  @override
  State<LogbookPage> createState() => _LogbookPageState();
}

class _LogbookPageState extends State<LogbookPage> {
  String? _username;
  int? _leaderId;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActiveExpeditions();
    });
  }

  /// Load semua ekspedisi aktif (tanpa auto-select)
  Future<void> _loadActiveExpeditions() async {
    if (!mounted) return;
    
    final logbookController = context.read<LogbookController>();

    try {
      // Load session hanya sekali
      if (!_isInitialized) {
        final session = await SessionManager.getUserSession();
        _username = session?['username'] ?? 'Unknown';
        _leaderId = session?['leaderId'] ?? 1;
        _isInitialized = true;
      }

      // Load semua ekspedisi aktif
      await logbookController.loadActiveExpeditions(_leaderId!);

      // Auto-select ekspedisi pertama jika ada
      if (mounted && logbookController.activeExpeditions.isNotEmpty) {
        // Cek apakah sudah ada yang dipilih
        if (logbookController.selectedExpedition == null) {
          await _selectExpedition(logbookController.activeExpeditions.first);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Gagal memuat ekspedisi: $e');
      }
    }
  }

  /// User memilih ekspedisi dari dropdown
  Future<void> _selectExpedition(ExpeditionModel expedition) async {
    if (_username == null) return;
    
    final logbookController = context.read<LogbookController>();
    
    // Tampilkan loading indicator
    if (mounted) {
      _showLoadingSnackBar('Memuat logbook ${expedition.expeditionName}...');
    }
    
    await logbookController.setSelectedExpedition(expedition, _username!);
  }

  /// Refresh data
  Future<void> _refreshData() async {
    await _loadActiveExpeditions();
    
    if (mounted) {
      _showSuccessSnackBar('Data berhasil diperbarui');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLoadingSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF4A8273),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: Consumer<LogbookController>(
        builder: (context, controller, _) {
          final selectedExpedition = controller.selectedExpedition;
          final activeExpeditions = controller.activeExpeditions;

          if (controller.isLoading && !_isInitialized) {
            return const EmptyStatesWidget.loading();
          }
          if (activeExpeditions.isEmpty) {
            return const EmptyStatesWidget.noActiveExpedition();
          }

          return RefreshIndicator(
            onRefresh: _refreshData,
            color: const Color(0xFF4A8273),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Expedition Selector
                  ExpeditionSelectorWidget(
                    expeditions: activeExpeditions,
                    selectedExpedition: selectedExpedition,
                    onExpeditionSelected: _selectExpedition,
                  ),
                  
                  // Info Ekspedisi yang Dipilih
                  if (selectedExpedition != null)
                    ExpeditionInfoCardWidget(
                      expedition: selectedExpedition,
                      logbookCount: controller.logbooks.length,
                    ),

                  const SizedBox(height: 30),
                
                  // Logbook Content
                  _buildLogbookContent(controller, selectedExpedition),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF4A8273),
      elevation: 0,
      title: Text(
        'Logbook Harian',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 20,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _refreshData,
          tooltip: 'Refresh Data',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return Consumer<LogbookController>(
      builder: (context, controller, _) {
        final expedition = controller.selectedExpedition;
        final isEnabled = expedition != null;

        return FloatingActionButton.extended(
          backgroundColor: isEnabled 
            ? const Color(0xFFE3DE61) 
            : Colors.grey[400],
          foregroundColor: isEnabled ? Colors.black : Colors.grey[600],
          elevation: isEnabled ? 4 : 0,
          onPressed: isEnabled ? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddLogbookPage(
                  expeditionId: expedition.expeditionId.toString(),
                  username: _username ?? expedition.leaderName,
                ),
              ),
            ).then((_) => _refreshData());
          } : null,
          icon: Icon(
            Icons.add, 
            size: 22,
            color: isEnabled ? Colors.black : Colors.grey[600],
          ),
          label: Text(
            'Tambah Logbook',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogbookContent(
    LogbookController controller,
    ExpeditionModel? selectedExpedition,
  ) {
    if (selectedExpedition == null) {
      return const EmptyStatesWidget.selectExpedition();
    }

    if (controller.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF4A8273),
          ),
        ),
      );
    }

    if (controller.logbooks.isEmpty) {
      return const EmptyStatesWidget.noLogbook();
    }

    return LogbookList(logbooks: controller.logbooks);
  }
}