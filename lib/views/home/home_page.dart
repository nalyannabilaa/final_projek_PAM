import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/logbook_controller.dart';
import '../../controllers/expedition_controller.dart';
import '../../models/logbook_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_appbar.dart';
import '../../utils/search_helper.dart';
import '../logbook/logbook_list.dart';
import '../logbook/add_logbook_page.dart';
import '../expedition/expedition_list_page.dart';
import 'card_expedition.dart';
import '../../services/session_manager.dart';

class HomePage extends StatefulWidget {
  final String username;
  final int leaderId;

  const HomePage({super.key, required this.username, required this.leaderId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  final List<String> motivationalQuotes = [
    "Petualangan adalah panggilan jiwa yang tidak bisa diabaikan.",
    "Setiap gunung yang didaki adalah pelajaran hidup yang berharga.",
    "Jejak kaki kita adalah cerita yang akan kita kenang selamanya.",
    "Alam mengajarkan kita untuk tetap rendah hati.",
    "Bukan puncak yang kita tuju, tapi perjalanan yang kita nikmati.",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    ExpeditionCardSection();
    });
  }



  Future<void> _loadData() async {
    final logbookController = context.read<LogbookController>();
    final expeditionController = context.read<ExpeditionController>();
    try {
      final session = await SessionManager.getUserSession();
      final username = session?['username'] ?? widget.username;
      final leaderId = session?['leaderId'] ?? widget.leaderId;
          final selectedExpedition = logbookController.selectedExpedition;

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
      }
    }
  }

  void _performSearch(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Consumer2<LogbookController, ExpeditionController>(
          builder: (context, logbookCtrl, expeditionCtrl, _) {
            final activeExpedition = logbookCtrl.selectedExpedition;
            final recentLogbooks = logbookCtrl.logbooks.take(3).toList();

            // Search results
            final searchQuery = _searchController.text;
            final searchedExpeditions = _isSearching
                ? SearchHelper.searchExpeditions(
                    expeditionCtrl.allExpeditions,
                    searchQuery,
                  )
                : <dynamic>[];

            return RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomAppBar(username: widget.username),
                    const SizedBox(height: 16),
                    _buildSearchBar(),

                    // Show search results or normal content
                    if (_isSearching)
                      _buildSearchResults(searchedExpeditions)
                    else ...[
                      const SizedBox(height: 16),
                      ExpeditionCardSection(),
                      const SizedBox(height: 24),
                      _buildLogbookSection(recentLogbooks, activeExpedition),
                      const SizedBox(height: 24),
                      _buildMotivationalQuote(),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _performSearch,
          decoration: InputDecoration(
            hintText: 'Cari ekspedisi...',
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: Color(0xFF4A8273),
              size: 22,
            ),
            suffixIcon: _isSearching
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _isSearching = false);
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildSearchResults(List<dynamic> results) {
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'Tidak ada hasil',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Coba kata kunci lain',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(
            'Hasil Pencarian (${results.length})',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3436),
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final expedition = results[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF4A8273).withOpacity(0.1),
                  child: const Icon(
                    Icons.hiking,
                    color: Color(0xFF4A8273),
                    size: 20,
                  ),
                ),
                title: Text(
                  expedition.expeditionName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  expedition.location,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(expedition.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    expedition.status.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(expedition.status),
                    ),
                  ),
                ),
                onTap: () {
                  // Navigate to expedition detail
                },
              ),
            );
          },
        ),
      ],
    );
  }


  Widget _buildLogbookSection(
    List<LogbookModel> logbooks,
    dynamic activeExpedition,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Logbook Terbaru',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (logbooks.isNotEmpty)
                TextButton(
                  onPressed: () {
                    // Navigate to all logbooks
                  },
                  child: Text(
                    'Lihat Semua',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF4A8273),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (logbooks.isEmpty)
           LogbookList(logbooks: logbooks)
        else
          LogbookList(logbooks: logbooks),
        const SizedBox(height: 16),
        if (activeExpedition != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CustomButton(
              label: "Tambahkan Logbook Hari Ini",
              icon: Icons.add_circle_outline,
              isFullWidth: true,
              backgroundColor: const Color(0xFF4A8273),
              textColor: Colors.white,
              borderRadius: 12,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddLogbookPage(
                      expeditionId: activeExpedition.expeditionId.toString(),
                      username: widget.username,
                    ),
                  ),
                ).then((_) => _loadData());
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyLogbookCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFBEDAD3).withOpacity(0.3),
          border: Border.all(color: const Color(0xFF4A8273).withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.book_outlined,
              size: 48,
              color: const Color(0xFF4A8273).withOpacity(0.6),
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada logbook',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: const Color(0xFF353533),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mulai catat perjalanan Anda',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationalQuote() {
    final quote = (motivationalQuotes..shuffle()).first;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              const Color(0xFFE3DE61).withOpacity(0.3),
              const Color(0xFFE3DE61).withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFFE3DE61).withOpacity(0.5)),
        ),
        child: Column(
          children: [
            const Icon(Icons.format_quote, color: Color(0xFF4A8273), size: 36),
            const SizedBox(height: 12),
            Text(
              quote,
              style: GoogleFonts.poppins(
                fontStyle: FontStyle.italic,
                color: const Color(0xFF2D3436),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aktif':
        return Colors.green;
      case 'akan datang':
        return Colors.orange;
      case 'selesai':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
