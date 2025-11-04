import 'package:hive/hive.dart';
part 'expedition_model.g.dart';

@HiveType(typeId: 1)
class ExpeditionModel extends HiveObject {
  @HiveField(0)
  int expeditionId; // ekspedisi_id (PK)

  @HiveField(1)
  int leaderId; // ketua_id (FK ke user_id)

  @HiveField(2)
  String leaderName; 

  @HiveField(3)
  String expeditionName; // nama_ekspedisi

  @HiveField(4)
  String location; // lokasi

  @HiveField(5)
  DateTime startDate; // tanggal_mulai

  @HiveField(6)
  DateTime endDate; // tanggal_selesai

  @HiveField(7)
  String status; // aktif, akan datang, selesai

  @HiveField(8)
  double totalBudget; // total_anggaran

  @HiveField(9)
  String currency; // mata_uang

  @HiveField(10)
  double convertedBudget; // total_anggaran_konversi

  @HiveField(11)
  String targetCurrency; // mata_uang_tujuan

  ExpeditionModel({
    required this.expeditionId,
    required this.leaderId,
    required this.leaderName,
    required this.expeditionName,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.totalBudget,
    required this.currency,
    required this.convertedBudget,
    required this.targetCurrency,
  });

  // Getter tambahan (optional)
  bool get isActive =>
      DateTime.now().isAfter(startDate) && DateTime.now().isBefore(endDate);

  bool get isUpcoming => DateTime.now().isBefore(startDate);

  bool get isCompleted => DateTime.now().isAfter(endDate);

  int get daysUntilStart => startDate.difference(DateTime.now()).inDays;

  int get daysRemaining => endDate.difference(DateTime.now()).inDays;

  // Convert to Map (untuk penyimpanan API / JSON)
  Map<String, dynamic> toMap() {
    return {
      'ekspedisi_id': expeditionId,
      'ketua_id': leaderId,
      'nama_ketua': leaderName,
      'nama_ekspedisi': expeditionName,
      'lokasi': location,
      'tanggal_mulai': startDate.toIso8601String(),
      'tanggal_selesai': endDate.toIso8601String(),
      'status': status,
      'total_anggaran': totalBudget,
      'mata_uang': currency,
      'total_anggaran_konversi': convertedBudget,
      'mata_uang_tujuan': targetCurrency,
    };
  }

  // Convert from Map
  factory ExpeditionModel.fromMap(Map<String, dynamic> map) {
    return ExpeditionModel(
      expeditionId: map['ekspedisi_id'],
      leaderId: map['ketua_id'],
      leaderName: map['nama_ketua'],
      expeditionName: map['nama_ekspedisi'],
      location: map['lokasi'],
          startDate: map['tanggal_mulai'] is String
        ? DateTime.parse(map['tanggal_mulai'])
        : map['tanggal_mulai'] as DateTime,
          endDate: map['tanggal_selesai'] is String
        ? DateTime.parse(map['tanggal_selesai'])
        : map['tanggal_selesai'] as DateTime,
      status: map['status'],
      totalBudget: (map['total_anggaran'] ?? 0).toDouble(),
      currency: map['mata_uang'],
      convertedBudget: (map['total_anggaran_konversi'] ?? 0).toDouble(),
      targetCurrency: map['mata_uang_tujuan'],
    );
  }
}
