import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/logbook_model.dart';

/// 🔹 Helper untuk mengekspor daftar logbook menjadi file .kml
/// agar dapat dibuka di Google Earth atau Google Maps.
class KMLExporter {
  /// Membuat file .kml berdasarkan daftar logbook dari satu ekspedisi.
  static Future<File> exportExpeditionRoute({
    required String expeditionName,
    required List<LogbookModel> logbooks,
  }) async {
    // Filter hanya logbook yang memiliki koordinat valid
    final points = logbooks
        .where((l) => l.latitude != null && l.longitude != null)
        .toList();

    if (points.isEmpty) {
      throw Exception('Tidak ada logbook dengan data koordinat untuk diekspor.');
    }

    // Urutkan berdasarkan tanggal agar rute berurutan sesuai perjalanan
    points.sort((a, b) => a.date.compareTo(b.date));

    // Buat struktur dasar file KML
    final kmlContent = _buildKMLContent(expeditionName, points);

    // Simpan ke direktori aplikasi
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$expeditionName.kml';

    final file = File(filePath);
    await file.writeAsString(kmlContent);

    return file;
  }

  /// 🔹 Bangun isi file .kml
  static String _buildKMLContent(String expeditionName, List<LogbookModel> logs) {
    final buffer = StringBuffer();

    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    buffer.writeln('<Document>');
    buffer.writeln('<name>${expeditionName}</name>');
    buffer.writeln('<description>Rute ekspedisi dari aplikasi Finpro Mobile</description>');

    // Gaya marker dan garis
    buffer.writeln('''
      <Style id="routeLine">
        <LineStyle>
          <color>ff4A8273</color> <!-- hijau toska -->
          <width>3</width>
        </LineStyle>
      </Style>

      <Style id="logMarker">
        <IconStyle>
          <color>ffE3DE61</color>
          <scale>1.1</scale>
          <Icon>
            <href>http://maps.google.com/mapfiles/kml/paddle/red-circle.png</href>
          </Icon>
        </IconStyle>
        <LabelStyle>
          <scale>0.8</scale>
        </LabelStyle>
      </Style>
    ''');

    // Tambahkan setiap titik logbook
    for (var log in logs) {
      buffer.writeln('''
        <Placemark>
          <name>${_escape(log.title)}</name>
          <description><![CDATA[
            <b>Tanggal:</b> ${log.formattedDate}<br/>
            <b>Lokasi:</b> ${_escape(log.location)}<br/>
            <b>Koordinat:</b> ${log.latitude}, ${log.longitude}<br/>
            <b>Cuaca:</b> ${log.weather ?? "Tidak diketahui"}<br/>
            <b>Kendala:</b> ${_escape(log.obstacle ?? "-")}<br/>
            <b>Saran:</b> ${_escape(log.suggestion ?? "-")}<br/>
            <b>Pengeluaran:</b> Rp ${log.dailyExpense.toStringAsFixed(2)}<br/>
            <b>Sisa Anggaran:</b> Rp ${log.remainingBudget.toStringAsFixed(2)}<br/>
            <b>Catatan:</b> ${_escape(log.shortContent)}<br/>
          ]]></description>
          <styleUrl>#logMarker</styleUrl>
          <Point>
            <coordinates>${log.longitude},${log.latitude},${log.elevation ?? 0}</coordinates>
          </Point>
        </Placemark>
      ''');
    }

    // Buat polyline untuk menggambar rute antar titik
    buffer.writeln('''
      <Placemark>
        <name>Rute Ekspedisi</name>
        <styleUrl>#routeLine</styleUrl>
        <LineString>
          <tessellate>1</tessellate>
          <altitudeMode>clampToGround</altitudeMode>
          <coordinates>
    ''');

    for (var log in logs) {
      buffer.writeln('    ${log.longitude},${log.latitude},${log.elevation ?? 0}');
    }

    buffer.writeln('''
          </coordinates>
        </LineString>
      </Placemark>
    ''');

    buffer.writeln('</Document>');
    buffer.writeln('</kml>');

    return buffer.toString();
  }

  /// 🔹 Escape teks agar aman di XML
  static String _escape(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
