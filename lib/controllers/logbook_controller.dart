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

  // === STATE LOGBOOK ===
  List<LogbookModel> _logbooks = [];
  List<LogbookModel> get logbooks => _logbooks;
  List<LogbookModel> _allLogbooks = [];
  List<LogbookModel> get allLogbooks => _allLogbooks;

  // === EKSPEDISI YANG DIPILIH USER ===
  ExpeditionModel? _selectedExpedition;
  ExpeditionModel? get selectedExpedition => _selectedExpedition;

  // === FILTER LOGBOOK ===
  String _selectedFilter = 'semua';
  String get selectedFilter => _selectedFilter;

  // === STATUS & BUDGET ===
  double _remainingBudget = 0;
  double get remainingBudget => _remainingBudget;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  File? _lastExportedKML;
  File? get lastExportedKML => _lastExportedKML;

//set ekspedisi yg dipilih
  void setSelectedExpedition(ExpeditionModel expedition) {
    if (_selectedExpedition?.expeditionId == expedition.expeditionId) return;
    _selectedExpedition = expedition;
    notifyListeners();
  }

//load logbooks ekspedisi yang dipilih
  Future<void> loadLogbooksForSelected(String username) async {
    if (_selectedExpedition == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final expeditionId = _selectedExpedition!.expeditionId.toString();

      // Ambil logbook dari Hive
      _logbooks = await _repository.getLogbooksByExpedition(expeditionId);
      _logbooks = _logbooks.where((l) => l.username == username).toList();
      _logbooks.sort((a, b) => b.date.compareTo(a.date));

      _allLogbooks = List.from(_logbooks);

      await _recalculateRemainingBudget(expeditionId);

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal memuat logbook: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _recalculateRemainingBudget(String expeditionId) async {
    final expedition = await _expeditionRepository.getExpeditionById(int.parse(expeditionId));
    if (expedition == null) return;

    final logs = await _repository.getLogbooksByExpedition(expeditionId);
    final totalSpent = logs.fold<double>(0, (sum, l) => sum + (l.dailyExpense ?? 0));
    final remaining = expedition.convertedBudget - totalSpent;

    _remainingBudget = remaining;

    for (var log in logs) {
      log.remainingBudget = remaining;
      await _repository.updateLogbook(log);
    }

    for (var log in _logbooks.where((l) => l.expeditionId == expeditionId)) {
      log.remainingBudget = remaining;
    }

    notifyListeners();
  }

  Future<void> addLogbook(LogbookModel logbook) async {
    try {
      await _repository.addLogbook(logbook);
      _logbooks.insert(0, logbook);
      _allLogbooks = List.from(_logbooks);
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
      await _recalculateRemainingBudget(expeditionId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal menghapus logbook: $e';
      notifyListeners();
    }
  }

  Future<File?> exportToKML(String expeditionId, {String? expeditionName}) async {
    try {
      final validLogs = _logbooks
          .where((l) => l.expeditionId == expeditionId && l.latitude != null && l.longitude != null)
          .toList();

      if (validLogs.isEmpty) throw Exception('Tidak ada koordinat valid');

      final file = await KMLExporter.exportExpeditionRoute(
        expeditionName: expeditionName ?? "Expedition_$expeditionId",
        logbooks: validLogs,
      );

      for (var log in validLogs) {
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
    return _logbooks.any((l) => l.expeditionId == expeditionId && l.syncedToKML);
  }


void clearExpeditionSelection() {
  if (_selectedExpedition != null) {
    _selectedExpedition = null;
    _logbooks.clear();
    _allLogbooks.clear();
    _remainingBudget = 0;
    notifyListeners();
  }
}

void validateAndClearIfDeleted(List<ExpeditionModel> allExpeditions) {
  if (_selectedExpedition == null) return;

  final exists = allExpeditions.any((e) => e.expeditionId == _selectedExpedition!.expeditionId);
  if (!exists) {
    _selectedExpedition = null;
    _logbooks.clear();
    _allLogbooks.clear();
    _remainingBudget = 0;
    notifyListeners();
  }
}
}