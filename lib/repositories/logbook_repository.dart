//digunakan untuk mengelola data logbook menggunakan Hive,
// termasuk menambah, mengambil, memperbarui, dan menghapus entri logbook.
import 'package:hive/hive.dart';
import '../../models/logbook_model.dart';

class LogbookRepository {
  static const String _boxName = 'logbooks_box';

  // ✅ Buka box Hive
  Future<Box<LogbookModel>> _openBox() async {
    return await Hive.openBox<LogbookModel>(_boxName);
  }

  // ✅ Tambah logbook baru
  Future<void> addLogbook(LogbookModel logbook) async {
    final box = await _openBox();
    await box.put(logbook.id, logbook);
  }

  // ✅ Ambil semua logbook
  Future<List<LogbookModel>> getAllLogbooks() async {
    final box = await _openBox();
    return box.values.toList();
  }

  // ✅ Ambil logbook berdasarkan ID
  Future<LogbookModel?> getLogbookById(String id) async {
    final box = await _openBox();
    return box.get(id);
  }

  // ✅ Ambil logbook berdasarkan username
  Future<List<LogbookModel>> getLogbooksByUser(String username) async {
    final box = await _openBox();
    return box.values
        .where((logbook) => logbook.username == username)
        .toList();
  }

  // ✅ Ambil logbook berdasarkan ekspedisi
  Future<List<LogbookModel>> getLogbooksByExpedition(String expeditionId) async {
    final box = await _openBox();
    return box.values
        .where((logbook) => logbook.expeditionId == expeditionId)
        .toList();
  }

  // ✅ Update logbook
  Future<void> updateLogbook(LogbookModel logbook) async {
    final box = await _openBox();
    await box.put(logbook.id, logbook);
  }

  // ✅ Hapus logbook
  Future<void> deleteLogbook(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }

  // ✅ Cari logbook berdasarkan judul atau lokasi
  Future<List<LogbookModel>> searchLogbooks(String query) async {
    final box = await _openBox();
    final lowerQuery = query.toLowerCase();

    return box.values
        .where((logbook) =>
            logbook.title.toLowerCase().contains(lowerQuery) ||
            logbook.location.toLowerCase().contains(lowerQuery))
        .toList();
  }

  // ✅ Kosongkan semua logbook
  Future<void> clearAllLogbooks() async {
    final box = await _openBox();
    await box.clear();
  }

}
