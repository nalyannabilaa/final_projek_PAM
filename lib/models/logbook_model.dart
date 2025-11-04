import 'package:hive/hive.dart';
part 'logbook_model.g.dart';

@HiveType(typeId: 2)
class LogbookModel extends HiveObject {
  @HiveField(0)
  String id; // Unique ID logbook (penting untuk KML marker ID)

  @HiveField(1)
  String expeditionId; // Ekspedisi terkait (rute dikelompokkan berdasarkan ini)

  @HiveField(2)
  String title;

  @HiveField(3)
  String content;

  @HiveField(4)
  DateTime date; // Tanggal logbook dibuat

  @HiveField(5)
  String location; // Nama lokasi (hasil reverse geocoding)

  @HiveField(6)
  double? latitude; // Posisi GPS
  @HiveField(7)
  double? longitude;

  @HiveField(8)
  double? elevation; // Tinggi dari permukaan laut (dari Open Elevation API)

  @HiveField(9)
  String? weather; // Cuaca saat itu (dari OpenWeatherMap)

  @HiveField(10)
  List<String> images; // Dokumentasi

  @HiveField(11)
  String username; // Penulis logbook

  @HiveField(12)
  DateTime createdAt;

  @HiveField(13)
  DateTime updatedAt;

  @HiveField(14)
  String? obstacle; // Kendala di lapangan

  @HiveField(15)
  String? suggestion; // Saran atau evaluasi

  @HiveField(16)
  double dailyExpense; // Pengeluaran hari ini

  @HiveField(17)
  double remainingBudget; // Sisa uang setelah hari ini

  @HiveField(18)
  bool syncedToKML; // Apakah sudah disertakan ke file .kml

  LogbookModel({
    required this.id,
    required this.expeditionId,
    required this.title,
    required this.content,
    this.obstacle,
    this.suggestion,
    required this.date,
    required this.location,
    this.latitude,
    this.longitude,
    this.elevation,
    this.weather,
    required this.images,
    required this.username,
    required this.createdAt,
    required this.updatedAt,
    this.dailyExpense = 0.0,
    this.remainingBudget = 0.0,
    this.syncedToKML = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expeditionId': expeditionId,
      'title': title,
      'content': content,
      'obstacle': obstacle,
      'suggestion': suggestion,
      'date': date.toIso8601String(),
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'elevation': elevation,
      'weather': weather,
      'images': images,
      'username': username,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'dailyExpense': dailyExpense,
      'remainingBudget': remainingBudget,
      'syncedToKML': syncedToKML,
    };
  }

  factory LogbookModel.fromMap(Map<String, dynamic> map) {
    return LogbookModel(
      id: map['id'],
      expeditionId: map['expeditionId'],
      title: map['title'],
      content: map['content'],
      obstacle: map['obstacle'],
      suggestion: map['suggestion'],
      date: DateTime.parse(map['date']),
      location: map['location'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      elevation: map['elevation'],
      weather: map['weather'],
      images: List<String>.from(map['images']),
      username: map['username'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      dailyExpense: (map['dailyExpense'] ?? 0).toDouble(),
      remainingBudget: (map['remainingBudget'] ?? 0).toDouble(),
      syncedToKML: map['syncedToKML'] ?? false,
    );
  }

  String get shortContent {
    if (content.length > 100) {
      return "${content.substring(0, 100)}...";
    }
    return content;
  }

  String get formattedDate {
    return "${date.day}/${date.month}/${date.year}";
  }

  LogbookModel copyWith({
    String? id,
    String? expeditionId,
    String? title,
    String? content,
    String? obstacle,
    String? suggestion,
    DateTime? date,
    String? location,
    double? latitude,
    double? longitude,
    double? elevation,
    String? weather,
    List<String>? images,
    String? username,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? dailyExpense,
    double? remainingBudget,
    bool? syncedToKML,
  }) {
    return LogbookModel(
      id: id ?? this.id,
      expeditionId: expeditionId ?? this.expeditionId,
      title: title ?? this.title,
      content: content ?? this.content,
      obstacle: obstacle ?? this.obstacle,
      suggestion: suggestion ?? this.suggestion,
      date: date ?? this.date,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      elevation: elevation ?? this.elevation,
      weather: weather ?? this.weather,
      images: images ?? List<String>.from(this.images),
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dailyExpense: dailyExpense ?? this.dailyExpense,
      remainingBudget: remainingBudget ?? this.remainingBudget,
      syncedToKML: syncedToKML ?? this.syncedToKML,
    );
  }
}
