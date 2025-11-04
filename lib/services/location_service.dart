import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart' as tz;

class LocationService {
  // ========== GPS LOCATION ==========
  
  /// Ambil posisi GPS pengguna
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Layanan lokasi belum diaktifkan.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak permanen.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
  }

  // ========== REVERSE GEOCODING ==========
  
  /// Ambil nama lokasi dari koordinat menggunakan Nominatim
  static Future<String> getLocationName(double lat, double lon) async {
    try {
      final url =
          'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json';
      final res = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Finpro-Mobile/1.0 (naylan@upnvyk.ac.id)',
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['display_name'] ?? 'Unknown Location';
      } else {
        return 'Unknown Location';
      }
    } catch (e) {
      return 'Unknown Location';
    }
  }

  // ========== WEATHER ==========
  
  /// Ambil informasi cuaca dari OpenWeatherMap
  static Future<String> getWeather(double lat, double lon) async {
    try {
      const apiKey = 'c7da5a1829193e65536eda3b81c95841';
      final url =
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric';
      final res = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final desc = data['weather'][0]['description'];
        final temp = data['main']['temp'];
        return '$desc (${temp.toStringAsFixed(1)}°C)';
      } else {
        return 'Unknown';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  // ========== ELEVATION ==========
  
  /// Ambil ketinggian (elevasi) dari koordinat
  static Future<double?> getElevation(double lat, double lon) async {
    try {
      final url =
          'https://api.open-elevation.com/api/v1/lookup?locations=$lat,$lon';
      final res = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['results'][0]['elevation'] as num).toDouble();
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // ========== TIMEZONE DETECTION ==========
  
  /// Deteksi timezone otomatis berdasarkan koordinat GPS
  static String detectTimezone(double lat, double lon) {
    // Indonesia timezone berdasarkan longitude
    // WIB: 95°E - 117°E (Sumatra, Jawa, Kalimantan Barat & Tengah)
    // WITA: 117°E - 130°E (Kalimantan Timur & Selatan, Sulawesi, Bali, NTB, NTT)
    // WIT: 130°E - 141°E (Maluku, Papua)
    
    if (lat >= -11 && lat <= 6 && lon >= 95 && lon <= 141) {
      // Di Indonesia
      if (lon >= 95 && lon < 117) {
        return 'Asia/Jakarta'; // WIB
      } else if (lon >= 117 && lon < 130) {
        return 'Asia/Makassar'; // WITA
      } else if (lon >= 130 && lon <= 141) {
        return 'Asia/Jayapura'; // WIT
      }
    }
    
    // Di luar Indonesia, coba deteksi timezone terdekat
    return _getClosestTimezone(lat, lon);
  }

  /// Helper untuk timezone di luar Indonesia
  static String _getClosestTimezone(double lat, double lon) {
    // Timezone berdasarkan longitude (simplified)
    // Timezone Asia yang umum
    if (lat >= -10 && lat <= 30 && lon >= 90 && lon <= 150) {
      if (lon >= 90 && lon < 105) return 'Asia/Bangkok'; // GMT+7
      if (lon >= 105 && lon < 120) return 'Asia/Jakarta'; // GMT+7
      if (lon >= 120 && lon < 135) return 'Asia/Makassar'; // GMT+8
      if (lon >= 135 && lon <= 150) return 'Asia/Tokyo'; // GMT+9
    }
    
    // Default ke Jakarta jika tidak terdeteksi
    return 'Asia/Jakarta';
  }

  /// Get current time dengan timezone tertentu
  static DateTime getTimeByTimezone(String timezone) {
    try {
      final location = tz.getLocation(timezone);
      return tz.TZDateTime.now(location);
    } catch (e) {
      return DateTime.now();
    }
  }

  // ========== COMBINED LOCATION DATA ==========
  
  /// Ambil semua data lokasi sekaligus (GPS, nama, cuaca, elevasi, timezone)
  static Future<Map<String, dynamic>> getCompleteLocationData() async {
    try {
      // 1. Ambil GPS position
      final position = await getCurrentPosition();
      final lat = position.latitude;
      final lon = position.longitude;

      // 2. Deteksi timezone otomatis
      final timezone = detectTimezone(lat, lon);

      // 3. Ambil data lainnya secara parallel
      final results = await Future.wait([
        getLocationName(lat, lon),
        getWeather(lat, lon),
        getElevation(lat, lon),
      ]);

      // 4. Get waktu dengan timezone yang terdeteksi
      final dateTime = getTimeByTimezone(timezone);

      return {
        'latitude': lat,
        'longitude': lon,
        'locationName': results[0],
        'weather': results[1],
        'elevation': results[2],
        'timezone': timezone,
        'dateTime': dateTime,
        'success': true,
        'error': null,
      };
    } catch (e) {
      return {
        'latitude': null,
        'longitude': null,
        'locationName': null,
        'weather': null,
        'elevation': null,
        'timezone': 'Asia/Jakarta',
        'dateTime': DateTime.now(),
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ========== TIMEZONE LIST ==========
  
  /// Daftar timezone yang tersedia
  static List<Map<String, String>> getTimezoneOptions() {
    return [
      {'name': 'WIB (Jakarta)', 'value': 'Asia/Jakarta'},
      {'name': 'WITA (Makassar)', 'value': 'Asia/Makassar'},
      {'name': 'WIT (Jayapura)', 'value': 'Asia/Jayapura'},
      {'name': 'Singapore', 'value': 'Asia/Singapore'},
      {'name': 'Bangkok', 'value': 'Asia/Bangkok'},
      {'name': 'Tokyo', 'value': 'Asia/Tokyo'},
      {'name': 'UTC', 'value': 'UTC'},
      {'name': 'GMT', 'value': 'GMT'},
    ];
  }
}