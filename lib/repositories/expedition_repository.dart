//diguakkan untuk mengelola data ekspedisi menggunakan Hive sebagai penyimpanan lokal.
//digunakan untuk menambah, mengambil, memperbarui, dan menghapus data ekspedisi.
import 'package:hive/hive.dart';
import '../../models/expedition_model.dart';
import '../../models/logbook_model.dart';
import '../controllers/logbook_controller.dart';

class ExpeditionRepository {
  static const String _boxName = 'expeditions_box';

  Future<Box<ExpeditionModel>> _openBox() async {
    return await Hive.openBox<ExpeditionModel>(_boxName);
  }
  Future<void> addExpedition(ExpeditionModel expedition) async {
    final box = await _openBox();
    await box.put(expedition.expeditionId, expedition);
  }

  Future<List<ExpeditionModel>> getAllExpeditions() async {
    final box = await _openBox();
    return box.values.toList();
  }
  Future<ExpeditionModel?> getExpeditionById(int expeditionId) async {
    final box = await _openBox();
    return box.get(expeditionId);
  }

  Future<List<ExpeditionModel>> getExpeditionsByLeader(int leaderId) async {
    final box = await _openBox();
    return box.values
        .where((expedition) => expedition.leaderId == leaderId)
        .toList();
  }

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

  Future<void> updateExpedition(ExpeditionModel expedition) async {
    final box = await _openBox();
    await box.put(expedition.expeditionId, expedition);
  }

Future<void> deleteExpedition(int expeditionId) async {
  final box = await _openBox();
  final expedition = box.get(expeditionId);
  if (expedition == null) return;

  await box.delete(expeditionId);

  final logbookBox = await Hive.openBox<LogbookModel>('logbooks_box');
  final logsToDelete = logbookBox.values
      .where((log) => log.expeditionId == expeditionId.toString())
      .toList();

  for (var log in logsToDelete) {
    await logbookBox.delete(log.id);
  }
}

  Future<List<ExpeditionModel>> searchExpeditions(String query) async {
    final box = await _openBox();
    final lowerQuery = query.toLowerCase();

    return box.values
        .where((expedition) =>
            expedition.expeditionName.toLowerCase().contains(lowerQuery) ||
            expedition.location.toLowerCase().contains(lowerQuery))
        .toList();
  }

Future<List<ExpeditionModel>> filterExpeditionsByStatus(
  int leaderId,
  String? status,
) async {
  final box = await _openBox();
  var expeditions = box.values
      .where((expedition) => expedition.leaderId == leaderId)
      .toList();

  if (status == null || status.toLowerCase() == 'semua') {
    return expeditions;
  }

  return expeditions
      .where((expedition) => 
          expedition.status.toLowerCase() == status.toLowerCase())
      .toList();
}

  Future<void> clearAllExpeditions() async {
    final box = await _openBox();
    await box.clear();
  }
}
