//diguakkan untuk mengelola data ekspedisi menggunakan Hive sebagai penyimpanan lokal.
//digunakan untuk menambah, mengambil, memperbarui, dan menghapus data ekspedisi.
import 'package:hive/hive.dart';
import '../../models/expedition_model.dart';
import '../../models/logbook_model.dart';

class ExpeditionRepository {
  static const String _boxName = 'expeditions_box';

  // ✅ Buka box Hive
  Future<Box<ExpeditionModel>> _openBox() async {
    return await Hive.openBox<ExpeditionModel>(_boxName);
  }

  // ✅ Tambah ekspedisi baru
  Future<void> addExpedition(ExpeditionModel expedition) async {
    final box = await _openBox();
    await box.put(expedition.expeditionId, expedition);
  }

  // ✅ Ambil semua ekspedisi
  Future<List<ExpeditionModel>> getAllExpeditions() async {
    final box = await _openBox();
    return box.values.toList();
  }

  // ✅ Ambil ekspedisi berdasarkan ID
  Future<ExpeditionModel?> getExpeditionById(int expeditionId) async {
    final box = await _openBox();
    return box.get(expeditionId);
  }

  // ✅ Ambil ekspedisi berdasarkan ketua (leader)
  Future<List<ExpeditionModel>> getExpeditionsByLeader(int leaderId) async {
    final box = await _openBox();
    return box.values
        .where((expedition) => expedition.leaderId == leaderId)
        .toList();
  }

  // ✅ Ambil ekspedisi aktif berdasarkan ketua
  Future<ExpeditionModel?> getActiveExpedition(int leaderId) async {
    final box = await _openBox();
    try {
      return box.values.firstWhere(
        (expedition) =>
            expedition.leaderId == leaderId && expedition.status == 'aktif',
      );
    } catch (e) {
      return null;
    }
  }

  // ✅ Ambil ekspedisi akan datang berdasarkan ketua
  Future<ExpeditionModel?> getUpcomingExpedition(int leaderId) async {
    final box = await _openBox();
    try {
      return box.values.firstWhere(
        (expedition) =>
            expedition.leaderId == leaderId &&
            expedition.status == 'akan datang',
      );
    } catch (e) {
      return null;
    }
  }

  // ✅ Update ekspedisi
  Future<void> updateExpedition(ExpeditionModel expedition) async {
    final box = await _openBox();
    await box.put(expedition.expeditionId, expedition);
  }

  // ✅ Hapus ekspedisi
  Future<void> deleteExpedition(int expeditionId) async {
    final box = await _openBox();
    await box.delete(expeditionId);

     // Hapus semua logbook yang terkait dengan ekspedisi ini
  final logbookBox = await Hive.openBox<LogbookModel>('logbooks_box');
  final logsToDelete = logbookBox.values
      .where((log) => log.expeditionId == expeditionId.toString())
      .toList();

  for (var log in logsToDelete) {
    await logbookBox.delete(log.id);
  }
  }

  // ✅ Cari ekspedisi berdasarkan nama atau lokasi
  Future<List<ExpeditionModel>> searchExpeditions(String query) async {
    final box = await _openBox();
    final lowerQuery = query.toLowerCase();

    return box.values
        .where((expedition) =>
            expedition.expeditionName.toLowerCase().contains(lowerQuery) ||
            expedition.location.toLowerCase().contains(lowerQuery))
        .toList();
  }

// ✅ Filter ekspedisi berdasarkan status
Future<List<ExpeditionModel>> filterExpeditionsByStatus(
  int leaderId,
  String? status,
) async {
  final box = await _openBox();
  var expeditions = box.values
      .where((expedition) => expedition.leaderId == leaderId)
      .toList();

  // Jika status null atau 'semua', return semua
  if (status == null || status.toLowerCase() == 'semua') {
    return expeditions;
  }

  // Filter berdasarkan status
  return expeditions
      .where((expedition) => 
          expedition.status.toLowerCase() == status.toLowerCase())
      .toList();
}

  // ✅ Kosongkan semua data ekspedisi
  Future<void> clearAllExpeditions() async {
    final box = await _openBox();
    await box.clear();
  }
}
