import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import '../../controllers/logbook_controller.dart';
import '../../controllers/expedition_controller.dart';
import '../../models/expedition_model.dart';
import '../../services/session_manager.dart';
import '../../widgets/custom_snackbar.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    try {
      final session = await SessionManager.getUserSession();
      _username = session?['username'] ?? 'Unknown';
      _leaderId = session?['leaderId'] ?? 1;

      final expeditionCtrl = context.read<ExpeditionController>();
      await expeditionCtrl.loadExpeditions(_leaderId!);

      final logbookCtrl = context.read<LogbookController>();
      logbookCtrl.validateAndClearIfDeleted(expeditionCtrl.allExpeditions);

      final activeExps = expeditionCtrl.activeExpeditions;
      if (logbookCtrl.selectedExpedition == null && 
          activeExps.isNotEmpty && 
          mounted) {
        final first = activeExps.first;
        logbookCtrl.setSelectedExpedition(first);
        await logbookCtrl.loadLogbooksForSelected(_username!);
      }

      _isInitialized = true;
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context,
          "Gagal memuat data: $e",
          type: SnackbarType.error,
        );
      }
    }
  }


  Future<void> _selectExpedition(ExpeditionModel expedition) async {
    if (_username == null || !mounted) return;

    final logbookCtrl = context.read<LogbookController>();
    _showLoadingSnackBar('Memuat logbook ${expedition.expeditionName}...');

    try {
      logbookCtrl.setSelectedExpedition(expedition);
      await logbookCtrl.loadLogbooksForSelected(_username!);
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context,
          "Gagal memuat logbook: $e",
          type: SnackbarType.error,
        );
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
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
                valueColor: AlwaysStoppedAnimation(Colors.white),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: Consumer2<ExpeditionController, LogbookController>(
        builder: (context, expCtrl, logCtrl, _) {
          // 🔥 Validasi setiap kali rebuild
          logCtrl.validateAndClearIfDeleted(expCtrl.allExpeditions);
          
          final activeExps = expCtrl.activeExpeditions;
          final selectedExp = logCtrl.selectedExpedition;

          // Loading awal
          if (expCtrl.isLoading && !_isInitialized) {
            return const EmptyStatesWidget.loading();
          }

          // Tidak ada ekspedisi aktif
          if (activeExps.isEmpty) {
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
                  // Selector
                  ExpeditionSelectorWidget(
                    expeditions: activeExps,
                    selectedExpedition: selectedExp,
                    onExpeditionSelected: _selectExpedition,
                  ),

                  // Info Ekspedisi
                  if (selectedExp != null)
                    ExpeditionInfoCardWidget(
                      expedition: selectedExp,
                      logbookCount: logCtrl.logbooks.length,
                    ),

                  const SizedBox(height: 30),

                  // Logbook List
                  _buildLogbookContent(selectedExp),

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
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return Consumer2<LogbookController, ExpeditionController>(
      builder: (context, logCtrl, expCtrl, _) {
        final exp = logCtrl.selectedExpedition;
        final activeExps = expCtrl.activeExpeditions;
        
        final isExpValid = exp != null && 
            activeExps.any((e) => e.expeditionId == exp.expeditionId);
        
        return FloatingActionButton.extended(
          backgroundColor: isExpValid 
              ? const Color(0xFFE3DE61) 
              : Colors.grey[400],
          onPressed: isExpValid
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddLogbookPage(
                        expeditionId: exp.expeditionId.toString(),
                        username: _username ?? exp.leaderName,
                      ),
                    ),
                  ).then((_) => _refreshData())
              : null,
          label: Text(
            isExpValid ? 'Tambah Logbook' : 'Pilih Ekspedisi',
            style: GoogleFonts.poppins(
              color: isExpValid ? Colors.black87 : Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          icon: Icon(
            isExpValid ? Icons.add : Icons.block,
            color: isExpValid ? Colors.black87 : Colors.white70,
          ),
        );
      },
    );
  }

  Widget _buildLogbookContent(ExpeditionModel? selectedExp) {
    final logCtrl = context.watch<LogbookController>();

    if (selectedExp == null) return const EmptyStatesWidget.selectExpedition();
    if (logCtrl.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF4A8273)),
        ),
      );
    }
    if (logCtrl.logbooks.isEmpty) return const EmptyStatesWidget.noLogbook();

    return LogbookList(logbooks: logCtrl.logbooks);
  }
}