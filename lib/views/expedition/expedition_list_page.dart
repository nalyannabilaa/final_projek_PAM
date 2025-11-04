import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import '../../controllers/expedition_controller.dart';
import '../../models/expedition_model.dart';
import '../../services/session_manager.dart';
import 'add_expedition_page.dart';
import './expedition_detail_page.dart';
import '../../utils/search_helper.dart';

class ExpeditionListPage extends StatefulWidget {
  const ExpeditionListPage({super.key});

  @override
  State<ExpeditionListPage> createState() => _ExpeditionListPageState();
}

class _ExpeditionListPageState extends State<ExpeditionListPage> {
  int? _leaderId;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) => _loadData());
  }

  Future<void> _loadData() async {
    final session = await SessionManager.getUserSession();
    _leaderId = session?['leaderId'] ?? 1;

    if (mounted) {
      final controller = context.read<ExpeditionController>();
      await controller.loadExpeditions(_leaderId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE3DE61),
        foregroundColor: Colors.black,
        elevation: 3,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddExpeditionPage(leaderId: _leaderId ?? 1),
            ),
          ).then((_) {
            if (mounted && _leaderId != null) {
              context.read<ExpeditionController>().loadExpeditions(_leaderId!);
            }
          });
        },
        icon: const Icon(Icons.add),
        label: Text(
          'Tambah Ekspedisi',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildFilterChips(context),
            Expanded(
              child: Consumer<ExpeditionController>(
                builder: (context, controller, child) {
                  if (controller.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4A8273),
                      ),
                    );
                  }

                  if (controller.errorMessage != null) {
                    return _buildErrorState(context, controller);
                  }

                  if (controller.expeditions.isEmpty) {
                    return _buildEmptyState(context, controller);
                  }

                  return _buildExpeditionList(controller.expeditions);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A8273), Color(0xFF6FA88E)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ekspedisi',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Consumer<ExpeditionController>(
                builder: (context, controller, child) {
                  return Text(
                    '${controller.allExpeditions.length} Total Ekspedisi',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return Consumer<ExpeditionController>(
      builder: (context, controller, child) {
        final counts = controller.getExpeditionCountByStatus();
        final filters = [
          {'label': 'Semua', 'value': 'semua', 'icon': Icons.apps},
          {
            'label': 'Aktif',
            'value': 'aktif',
            'icon': Icons.play_circle_filled,
          },
          {
            'label': 'Akan Datang',
            'value': 'akan datang',
            'icon': Icons.schedule,
          },
          {'label': 'Selesai', 'value': 'selesai', 'icon': Icons.check_circle},
        ];

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: filters.map((filter) {
                final isSelected =
                    controller.selectedFilter.toLowerCase() ==
                    filter['value'].toString().toLowerCase();
                final count = counts[filter['value'].toString()] ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          filter['icon'] as IconData,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF4A8273),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${filter['label']} ($count)',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF4A8273),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF4A8273),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF4A8273)
                            : Colors.grey[300]!,
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        controller.setFilter(filter['value'].toString());
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ExpeditionController controller,
  ) {
    final isFiltered = controller.selectedFilter.toLowerCase() != 'semua';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFiltered ? Icons.filter_alt_off : Icons.hiking,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered
                  ? 'Tidak Ada Ekspedisi ${controller.selectedFilter.toUpperCase()}'
                  : 'Belum Ada Ekspedisi',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Coba filter lain atau tambah ekspedisi baru'
                  : 'Mulai rencanakan petualanganmu!',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (isFiltered) ...[
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () => controller.resetFilter(),
                icon: const Icon(Icons.clear_all),
                label: Text('Reset Filter', style: GoogleFonts.poppins()),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4A8273),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    ExpeditionController controller,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Terjadi Kesalahan',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              controller.errorMessage!,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_leaderId != null) {
                controller.loadExpeditions(_leaderId!);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A8273),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildExpeditionList(List<ExpeditionModel> expeditions) {
    return RefreshIndicator(
      onRefresh: () async {
        if (_leaderId != null) {
          await context.read<ExpeditionController>().loadExpeditions(
            _leaderId!,
          );
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: expeditions.length,
        itemBuilder: (context, index) {
          return _buildExpeditionCard(context, expeditions[index]);
        },
      ),
    );
  }

  Widget _buildExpeditionCard(
    BuildContext context,
    ExpeditionModel expedition,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ExpeditionDetailPage(expedition: expedition),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      expedition.expeditionName,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        expedition.status,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(expedition.status),
                          size: 14,
                          color: _getStatusColor(expedition.status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          expedition.status.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(expedition.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      expedition.location,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${DateFormat('d MMM y').format(expedition.startDate)} - ${DateFormat('d MMM y').format(expedition.endDate)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: '${expedition.targetCurrency} ',
                      decimalDigits: 2,
                    ).format(
                      double.parse(expedition.convertedBudget.toString()),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aktif':
        return Colors.green;
      case 'selesai':
        return Colors.blue;
      case 'akan datang':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'aktif':
        return Icons.play_circle_filled;
      case 'selesai':
        return Icons.check_circle;
      case 'akan datang':
        return Icons.schedule;
      default:
        return Icons.info;
    }
  }
}
