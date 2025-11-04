import '../models/expedition_model.dart';
import '../models/logbook_model.dart';

/// Helper class untuk search functionality
/// Bisa digunakan di berbagai halaman
class SearchHelper {
  /// Search ekspedisi berdasarkan nama atau lokasi
  static List<ExpeditionModel> searchExpeditions(
    List<ExpeditionModel> expeditions,
    String query,
  ) {
    if (query.isEmpty) return expeditions;

    final lowerQuery = query.toLowerCase().trim();
    
    return expeditions.where((expedition) {
      final name = expedition.expeditionName.toLowerCase();
      final location = expedition.location.toLowerCase();
      final status = expedition.status.toLowerCase();
      
      return name.contains(lowerQuery) ||
             location.contains(lowerQuery) ||
             status.contains(lowerQuery);
    }).toList();
  }

  /// Search logbook berdasarkan title, content, atau location
  static List<LogbookModel> searchLogbooks(
    List<LogbookModel> logbooks,
    String query,
  ) {
    if (query.isEmpty) return logbooks;

    final lowerQuery = query.toLowerCase().trim();
    
    return logbooks.where((logbook) {
      final title = logbook.title.toLowerCase();
      final content = logbook.content.toLowerCase();
      final location = logbook.location?.toLowerCase() ?? '';
      
      return title.contains(lowerQuery) ||
             content.contains(lowerQuery) ||
             location.contains(lowerQuery);
    }).toList();
  }

  /// Highlight matching text in search results
  static String highlightMatch(String text, String query) {
    if (query.isEmpty) return text;
    
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    
    if (!lowerText.contains(lowerQuery)) return text;
    
    final startIndex = lowerText.indexOf(lowerQuery);
    final endIndex = startIndex + query.length;
    
    return text.substring(0, startIndex) +
           '**${text.substring(startIndex, endIndex)}**' +
           text.substring(endIndex);
  }

  /// Get search suggestions based on recent searches
  static List<String> getSearchSuggestions(
    List<ExpeditionModel> expeditions,
    String query,
  ) {
    if (query.length < 2) return [];

    final suggestions = <String>{};
    final lowerQuery = query.toLowerCase();

    for (var expedition in expeditions) {
      // Nama ekspedisi suggestions
      if (expedition.expeditionName.toLowerCase().contains(lowerQuery)) {
        suggestions.add(expedition.expeditionName);
      }
      
      // Lokasi suggestions
      if (expedition.location.toLowerCase().contains(lowerQuery)) {
        suggestions.add(expedition.location);
      }
    }

    return suggestions.take(5).toList(); // Max 5 suggestions
  }
}