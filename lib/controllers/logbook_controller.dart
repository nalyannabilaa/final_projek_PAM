import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/logbook_model.dart';
import '../../models/expedition_model.dart';
import '../../repositories/logbook_repository.dart';
import '../../repositories/expedition_repository.dart';
import '../../utils/kml_exporter.dart';

class LogbookController extends ChangeNotifier {
  final LogbookRepository _repository = LogbookRepository();
  final ExpeditionRepository _expeditionRepository = ExpeditionRepository();

  List<LogbookModel> _logbooks = [];
  List<LogbookModel> get logbooks => _logbooks;
  List<LogbookModel> _allLogbooks = [];

  String _selectedFilter = 'semua';
  String get selectedFilter => _selectedFilter;

  // ✅ Simpan ekspedisi yang dipilih user (bukan otomatis)
  ExpeditionModel? _selectedExpedition;
  ExpeditionModel? get selectedExpedition => _selectedExpedition;

  // ✅ List semua ekspedisi aktif (untuk dropdown)
  List<ExpeditionModel> _activeExpeditions = [];
  List<ExpeditionModel> get activeExpeditions => _activeExpeditions;

  double _remainingBudget = 0;
  double get remainingBudget => _remainingBudget;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  File? _lastExportedKML;
  File? get lastExportedKML => _lastExportedKML;

  List<LogbookModel> get allLogbooks => _allLogbooks;

  ExpeditionModel? get activeExpedition => _selectedExpedition;

  // =============================================================
  // 🔍 HELPER: Tentukan Ekspedisi Aktif
  // =============================================================
  
  /// Filter ekspedisi yang benar-benar aktif berdasarkan tanggal
  List<ExpeditionModel> _filterActiveExpeditions(List<ExpeditionModel> expeditions) {
    final now = DateTime.now();
    
    return expeditions.where((e) {
      final isDateActive = (now.isAfter(e.startDate) || now.isAtSameMomentAs(e.startDate)) &&
                           (now.isBefore(e.endDate) || now.isAtSameMomentAs(e.endDate));
      final isStatusActive = e.status.toLowerCase().trim().contains('aktif');
      
      return isDateActive && isStatusActive;
    }).toList();
  }

  // =============================================================
  // 🧭 LOAD SEMUA EKSPEDISI AKTIF (Tanpa Auto-Select)
  // =============================================================
  
  Future<void> loadActiveExpeditions(int leaderId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final expeditions = await _expeditionRepository.getExpeditionsByLeader(leaderId);
      
      // Filter ekspedisi yang aktif
      _activeExpeditions = _filterActiveExpeditions(expeditions);
      
      // Sort by start date (terbaru dulu)
      _activeExpeditions.sort((a, b) => b.startDate.compareTo(a.startDate));

      _errorMessage = _activeExpeditions.isEmpty 
        ? 'Tidak ada ekspedisi aktif saat ini.' 
        : null;
        
    } catch (e) {
      _errorMessage = 'Gagal memuat ekspedisi aktif: $e';
      _activeExpeditions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =============================================================
  // 🎯 SET EKSPEDISI AKTIF (Pilihan User)
  // =============================================================
  
  /// Set ekspedisi yang dipilih user dan load logbooknya
  Future<void> setSelectedExpedition(ExpeditionModel expedition, String username) async {
    if (_selectedExpedition?.expeditionId == expedition.expeditionId) {
      return; // Sudah terpilih, skip
    }

    _isLoading = true;
    _selectedExpedition = expedition;
    notifyListeners();

    try {
      await loadLogbooksByExpedition(
        expedition.expeditionId.toString(),
        username,
      );
    } catch (e) {
      _errorMessage = 'Gagal memuat logbook: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // =============================================================
  // 📗 LOAD LOGBOOK BERDASARKAN EKSPEDISI
  // =============================================================
  
  Future<void> loadLogbooksByExpedition(String expeditionId, String username) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Cari ekspedisi by ID
      final expedition = await _expeditionRepository.getExpeditionById(int.parse(expeditionId));
      
      if (expedition == null) {
        throw Exception('Ekspedisi tidak ditemukan');
      }

      _selectedExpedition = expedition;

      // Load logbook untuk ekspedisi ini
      _logbooks = await _repository.getLogbooksByExpedition(expeditionId);
      _logbooks = _logbooks.where((l) => l.username == username).toList();
      _logbooks.sort((a, b) => b.date.compareTo(a.date));

      _allLogbooks = List.from(_logbooks);
      _applyFilter();

      await _recalculateRemainingBudget(expeditionId);
      
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal memuat logbook: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =============================================================
  // 🔄 LOAD INITIAL (Untuk Backward Compatibility)
  // =============================================================
  
  /// Load ekspedisi aktif + auto-select yang pertama
  /// Gunakan ini jika ingin behavior lama (auto-select)
  Future<void> loadActiveExpeditionWithAutoSelect(int leaderId, String username) async {
    await loadActiveExpeditions(leaderId);
    
    if (_activeExpeditions.isNotEmpty) {
      await setSelectedExpedition(_activeExpeditions.first, username);
    }
  }

  // =============================================================
  // 💰 Fungsi Hitung Ulang Sisa Anggaran
  // =============================================================
  
  Future<void> _recalculateRemainingBudget(String expeditionId) async {
    final expedition = await _expeditionRepository.getExpeditionById(
      int.parse(expeditionId),
    );
    if (expedition == null) return;

    final expeditionLogs = await _repository.getLogbooksByExpedition(
      expeditionId,
    );

    final totalSpent = expeditionLogs.fold<double>(
      0,
      (sum, l) => sum + (l.dailyExpense ?? 0),
    );

    final remaining = expedition.convertedBudget - totalSpent;
    _remainingBudget = remaining;

    for (var log in expeditionLogs) {
      log.remainingBudget = remaining;
      await _repository.updateLogbook(log);
    }

    for (var log in _logbooks.where((l) => l.expeditionId == expeditionId)) {
      log.remainingBudget = remaining;
    }

    notifyListeners();
  }

  // =============================================================
  // ➕ TAMBAH / UPDATE / HAPUS
  // =============================================================
  
  Future<void> addLogbook(LogbookModel logbook) async {
    try {
      await _repository.addLogbook(logbook);
      _logbooks.insert(0, logbook);
      _allLogbooks = List.from(_logbooks);
      _applyFilter();
      await _recalculateRemainingBudget(logbook.expeditionId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal menambah logbook: $e';
      notifyListeners();
    }
  }

  Future<void> updateLogbook(LogbookModel logbook) async {
    try {
      await _repository.updateLogbook(logbook);
      final index = _logbooks.indexWhere((l) => l.id == logbook.id);
      if (index != -1) _logbooks[index] = logbook;
      _allLogbooks = List.from(_logbooks);
      _applyFilter();
      await _recalculateRemainingBudget(logbook.expeditionId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal memperbarui logbook: $e';
      notifyListeners();
    }
  }

  Future<void> deleteLogbook(String id, String expeditionId) async {
    try {
      await _repository.deleteLogbook(id);
      _logbooks.removeWhere((l) => l.id == id);
      _allLogbooks = List.from(_logbooks);
      _applyFilter();
      await _recalculateRemainingBudget(expeditionId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal menghapus logbook: $e';
      notifyListeners();
    }
  }

  // =============================================================
  // 🗺️ KML EXPORT
  // =============================================================
  
  Future<File?> exportToKML(
    String expeditionId, {
    String? expeditionName,
  }) async {
    try {
      final expeditionLogs = _logbooks
          .where(
            (l) =>
                l.expeditionId == expeditionId &&
                l.latitude != null &&
                l.longitude != null,
          )
          .toList();

      if (expeditionLogs.isEmpty) {
        throw Exception('Tidak ada logbook dengan koordinat valid.');
      }

      final name = expeditionName ?? "Expedition_$expeditionId";
      final file = await KMLExporter.exportExpeditionRoute(
        expeditionName: name,
        logbooks: expeditionLogs,
      );

      for (var log in expeditionLogs) {
        log.syncedToKML = true;
        await _repository.updateLogbook(log);
      }

      _lastExportedKML = file;
      notifyListeners();

      return file;
    } catch (e) {
      _errorMessage = 'Gagal ekspor KML: $e';
      notifyListeners();
      return null;
    }
  }

  bool isExpeditionSynced(String expeditionId) {
    return _logbooks.any(
      (l) => l.expeditionId == expeditionId && l.syncedToKML,
    );
  }

  // =============================================================
  // 🔍 FILTER METHODS
  // =============================================================
  
  void setFilter(String filter) {
    _selectedFilter = filter;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    final now = DateTime.now();
    
    if (_selectedFilter == 'semua') {
      _logbooks = List.from(_allLogbooks);
    } else if (_selectedFilter == 'hari_ini') {
      _logbooks = _allLogbooks.where((log) {
        return log.date.year == now.year &&
               log.date.month == now.month &&
               log.date.day == now.day;
      }).toList();
    } else if (_selectedFilter == 'minggu_ini') {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      
      _logbooks = _allLogbooks.where((log) {
        return log.date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
               log.date.isBefore(endOfWeek.add(const Duration(days: 1)));
      }).toList();
    } else if (_selectedFilter == 'bulan_ini') {
      _logbooks = _allLogbooks.where((log) {
        return log.date.year == now.year && log.date.month == now.month;
      }).toList();
    }
  }

  void resetFilter() {
    _selectedFilter = 'semua';
    _applyFilter();
    notifyListeners();
  }

  Map<String, int> getLogbookCountByFilter() {
    final now = DateTime.now();
    
    return {
      'semua': _allLogbooks.length,
      'hari_ini': _allLogbooks.where((log) {
        return log.date.year == now.year &&
               log.date.month == now.month &&
               log.date.day == now.day;
      }).length,
      'minggu_ini': _allLogbooks.where((log) {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return log.date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
               log.date.isBefore(endOfWeek.add(const Duration(days: 1)));
      }).length,
      'bulan_ini': _allLogbooks.where((log) {
        return log.date.year == now.year && log.date.month == now.month;
      }).length,
    };
  }

  // =============================================================
  // 🧹 CLEAR SELECTION
  // =============================================================
  
  void clearSelection() {
    _selectedExpedition = null;
    _logbooks = [];
    _allLogbooks = [];
    _remainingBudget = 0;
    notifyListeners();
  }
}