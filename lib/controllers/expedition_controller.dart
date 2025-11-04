// digunakan untuk mengelola data ekspedisi menggunakan ChangeNotifier,
// termasuk mengambil, menambah, memperbarui, menghapus, dan mencari data ekspedisi.
import 'package:flutter/foundation.dart';
import '../models/expedition_model.dart';
import '../repositories/expedition_repository.dart';

class ExpeditionController extends ChangeNotifier {
  final ExpeditionRepository _repository = ExpeditionRepository();

  List<ExpeditionModel> _expeditions = [];
  List<ExpeditionModel> _allExpeditions = []; // Simpan semua data
  ExpeditionModel? _activeExpedition;
  ExpeditionModel? _upcomingExpedition;

  bool _isLoading = false;
  String? _errorMessage;
  String _selectedFilter = 'semua'; // Filter yang dipilih

  // ===== Getter =====
  List<ExpeditionModel> get expeditions => _expeditions;
  List<ExpeditionModel> get allExpeditions => _allExpeditions;
  ExpeditionModel? get activeExpedition => _activeExpedition;
  ExpeditionModel? get upcomingExpedition => _upcomingExpedition;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedFilter => _selectedFilter;

  // ===== Set filter =====
  void setFilter(String filter) {
    _selectedFilter = filter;
    _applyFilter();
    notifyListeners();
  }

  // ===== Apply filter ke data =====
  void _applyFilter() {
    if (_selectedFilter.toLowerCase() == 'semua') {
      _expeditions = List.from(_allExpeditions);
    } else {
      _expeditions = _allExpeditions
          .where((expedition) =>
              expedition.status.toLowerCase() == _selectedFilter.toLowerCase())
          .toList();
    }
  }

  // ===== Ambil semua data ekspedisi =====
  Future<void> loadExpeditions(int leaderId) async {
    _isLoading = true;
    notifyListeners();

    try {
      var expeditions = await _repository.getExpeditionsByLeader(leaderId);

      final now = DateTime.now();
      bool statusChanged = false;

      // 🔹 Update status otomatis berdasarkan tanggal
      for (var expedition in expeditions) {
        String newStatus;

        if (now.isBefore(expedition.startDate)) {
          newStatus = 'akan datang';
        } else if (now.isAfter(expedition.endDate)) {
          newStatus = 'selesai';
        } else {
          newStatus = 'aktif';
        }

        // Jika status lama berbeda, update di Hive
        if (expedition.status != newStatus) {
          expedition.status = newStatus;
          await _repository.updateExpedition(expedition);
          statusChanged = true;
        }
      }

      // Urutkan sehingga: status 'aktif' di atas, lalu 'akan datang', lalu 'selesai', lalu lainnya.
      expeditions.sort((a, b) {
        int priority(String s) {
          final st = s.toLowerCase();
          if (st == 'aktif') return 0;
          if (st == 'akan datang') return 1;
          if (st == 'selesai') return 2;
          return 3;
        }

        final pa = priority(a.status);
        final pb = priority(b.status);

        if (pa != pb) return pa.compareTo(pb);

        final diffA = a.startDate.difference(now).abs();
        final diffB = b.startDate.difference(now).abs();
        return diffA.compareTo(diffB);
      });

      _allExpeditions = expeditions;
      _applyFilter(); // Apply filter setelah load

      // Cari ekspedisi aktif / akan datang
      final activeList = expeditions
          .where((e) => e.status.toLowerCase() == 'aktif')
          .toList();
      _activeExpedition = activeList.isNotEmpty ? activeList.first : null;

      final upcomingList = expeditions
          .where((e) => e.status.toLowerCase() == 'akan datang')
          .toList();
      _upcomingExpedition = upcomingList.isNotEmpty ? upcomingList.first : null;

      if (statusChanged && kDebugMode) {
        print("🟢 Status ekspedisi diperbarui otomatis berdasarkan tanggal.");
      }

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal memuat data ekspedisi: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ===== Reset filter =====
  void resetFilter() {
    _selectedFilter = 'semua';
    _applyFilter();
    notifyListeners();
  }

  // ===== Get jumlah ekspedisi per status =====
  Map<String, int> getExpeditionCountByStatus() {
    return {
      'semua': _allExpeditions.length,
      'aktif': _allExpeditions
          .where((e) => e.status.toLowerCase() == 'aktif')
          .length,
      'akan datang': _allExpeditions
          .where((e) => e.status.toLowerCase() == 'akan datang')
          .length,
      'selesai': _allExpeditions
          .where((e) => e.status.toLowerCase() == 'selesai')
          .length,
    };
  }

  // ===== Tambah ekspedisi =====
  Future<void> addExpedition(ExpeditionModel expedition) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.addExpedition(expedition);
      _allExpeditions = await _repository.getAllExpeditions();
      _applyFilter();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal menambah ekspedisi: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ===== Update ekspedisi =====
  Future<void> updateExpedition(ExpeditionModel expedition) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.updateExpedition(expedition);
      _allExpeditions = await _repository.getAllExpeditions();
      _applyFilter();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal memperbarui ekspedisi: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ===== Hapus ekspedisi =====
  Future<void> deleteExpedition(int expeditionId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.deleteExpedition(expeditionId);
      _allExpeditions = await _repository.getAllExpeditions();
      _applyFilter();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal menghapus ekspedisi: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ===== Cari ekspedisi berdasarkan nama/lokasi =====
  Future<void> searchExpeditions(String query) async {
    if (query.isEmpty) {
      _applyFilter(); // Reset ke filter yang aktif
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _expeditions = await _repository.searchExpeditions(query);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal mencari ekspedisi: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ===== Hapus semua ekspedisi =====
  Future<void> clearAllExpeditions() async {
    await _repository.clearAllExpeditions();
    _expeditions = [];
    _allExpeditions = [];
    _activeExpedition = null;
    _upcomingExpedition = null;
    notifyListeners();
  }
}