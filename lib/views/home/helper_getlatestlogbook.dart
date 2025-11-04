import '../../models/logbook_model.dart';
import '../../models/expedition_model.dart';

class ExpeditionLogbookHelper {
  final List<LogbookModel> logbooks;

  ExpeditionLogbookHelper({required this.logbooks});

  /// Mengambil logbook terbaru dari sebuah ekspedisi
  LogbookModel? getLatestLogbook(ExpeditionModel expedition) {
    final expeditionLogs = logbooks
        .where((log) => log.expeditionId == expedition.expeditionId.toString())
        .toList();

    if (expeditionLogs.isEmpty) return null;

    // Urutkan dari yang terbaru
    expeditionLogs.sort((a, b) => b.date.compareTo(a.date));
    return expeditionLogs.first;
  }

  /// Ambil gambar terbaru untuk ekspedisi
  String getLatestLogbookImage(ExpeditionModel expedition) {
    final latestLog = getLatestLogbook(expedition);
    if (latestLog == null || latestLog.images.isEmpty) {
      // fallback dummy image
      return 'https://static.vecteezy.com/system/resources/previews/009/169/498/non_2x/sunset-landscape-over-mountains-with-a-traveler-standing-on-the-top-of-hill-vector.jpg';
    }
    return latestLog.images.first;
  }
}
