import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:path_provider/path_provider.dart';

class RadioStation {
  final String id;
  final String name;
  final String streamUrl;
  final String frequency;
  final Color primaryColor;
  final Color secondaryColor;
  final String description;
  final String? logoUrl;

  const RadioStation({
    required this.id,
    required this.name,
    required this.streamUrl,
    required this.frequency,
    required this.primaryColor,
    required this.secondaryColor,
    required this.description,
    this.logoUrl,
  });

  factory RadioStation.fromJson(Map<String, dynamic> json) {
    Color parseColor(String hex) {
      final cleanHex = hex.replaceAll('#', '').replaceAll('0x', '');
      if (cleanHex.length == 6) {
        return Color(int.parse('FF$cleanHex', radix: 16));
      } else if (cleanHex.length == 8) {
        return Color(int.parse(cleanHex, radix: 16));
      }
      return Colors.blue;
    }

    return RadioStation(
      id: json['id'] as String,
      name: json['name'] as String,
      streamUrl: json['streamUrl'] as String,
      frequency: json['frequency'] as String,
      primaryColor: parseColor(json['primaryColor'] as String),
      secondaryColor: parseColor(json['secondaryColor'] as String),
      description: json['description'] as String,
      logoUrl: json['logoUrl'] as String?,
    );
  }

  // Default fallback stations to prevent Android Auto timeout and empty UI
  static final List<RadioStation> defaultStations = [
    const RadioStation(
      id: "hiru_fm",
      name: "Hiru FM",
      streamUrl: "https://radio.lotustechnologieslk.net:2020/stream/hirufmgarden",
      frequency: "96.1 MHz",
      primaryColor: Color(0xFFD32F2F),
      secondaryColor: Color(0xFFFF5722),
      description: "Sri Lanka's Number One Sinhala Radio Channel",
      logoUrl: "https://www.gavixapps.com/radio/hiru-fm.png",
    ),
    const RadioStation(
      id: "fm_derana",
      name: "FM Derana",
      streamUrl: "https://cp12.serverse.com/proxy/fmderana/stream",
      frequency: "92.2 MHz",
      primaryColor: Color(0xFFFF8F00),
      secondaryColor: Color(0xFFFFC107),
      description: "Lankeya Sith Neth Niwana Derana",
      logoUrl: "https://www.gavixapps.com/radio/fm-derana.png",
    ),
    const RadioStation(
      id: "neth_fm",
      name: "Neth FM",
      streamUrl: "https://cp11.serverse.com/proxy/nethfm/stream",
      frequency: "98.9 MHz",
      primaryColor: Color(0xFF0D47A1),
      secondaryColor: Color(0xFF1976D2),
      description: "The Radio for All Sri Lankans",
      logoUrl: "https://www.gavixapps.com/radio/neth-fm.png",
    ),
    const RadioStation(
      id: "siyatha_fm",
      name: "Siyatha FM",
      streamUrl: "https://srv01.onlineradio.voaplus.com/siyathafm",
      frequency: "98.2 MHz",
      primaryColor: Color(0xFF6A1B9A),
      secondaryColor: Color(0xFFAB47BC),
      description: "Vibrant Music and Hits All Day Long",
      logoUrl: "https://www.gavixapps.com/radio/siyatha-fm.png",
    ),
    const RadioStation(
      id: "lakhanda_fm",
      name: "Lakhanda FM",
      streamUrl: "https://cp12.serverse.com/proxy/itnfm?mp=/stream",
      frequency: "93.7 MHz",
      primaryColor: Color(0xFF2E7D32),
      secondaryColor: Color(0xFF4CAF50),
      description: "The Golden Heartbeat of the Nation",
      logoUrl: "https://www.gavixapps.com/radio/lakhanda-fm.png",
    ),
    const RadioStation(
      id: "gold_fm",
      name: "Gold FM",
      streamUrl: "https://radio.lotustechnologieslk.net:8000/",
      frequency: "93.0 MHz",
      primaryColor: Color(0xFFFFD700),
      secondaryColor: Color(0xFF8B6508),
      description: "Sri Lanka's Golden Classics English Station",
      logoUrl: "https://www.gavixapps.com/radio/gold-fm.png",
    ),
    const RadioStation(
      id: "kiss_fm",
      name: "Kiss FM",
      streamUrl: "https://srv01.onlineradio.voaplus.com/kissfm",
      frequency: "96.9 MHz",
      primaryColor: Color(0xFFE91E63),
      secondaryColor: Color(0xFF1A1A1A),
      description: "The Sound of Your Future",
      logoUrl: "https://www.gavixapps.com/radio/kiss-fm.png",
    ),
    const RadioStation(
      id: "light_fm",
      name: "Light FM",
      streamUrl: "https://srv01.onlineradio.voaplus.com/lite878",
      frequency: "87.8 MHz",
      primaryColor: Color(0xFF00BFFF),
      secondaryColor: Color(0xFF1E3C72),
      description: "Lite 87 - Easy Listening Favorites",
      logoUrl: "https://www.gavixapps.com/radio/light-fm.png",
    ),
    const RadioStation(
      id: "real_radio",
      name: "Real Radio",
      streamUrl: "https://srv01.onlineradio.voaplus.com/realfm",
      frequency: "97.1 MHz",
      primaryColor: Color(0xFF008080),
      secondaryColor: Color(0xFF0F2027),
      description: "Real Radio - real music, real talk",
      logoUrl: "https://www.gavixapps.com/radio/real-radio.png",
    ),
    const RadioStation(
      id: "rhythm_fm",
      name: "Rhythm FM",
      streamUrl: "https://srv01.onlineradio.voaplus.com/rhythmfm",
      frequency: "95.6 MHz",
      primaryColor: Color(0xFFF27121),
      secondaryColor: Color(0xFFE94057),
      description: "Feel the Rhythm of Your Life",
      logoUrl: "https://www.gavixapps.com/radio/rhythm-fm.png",
    ),
    const RadioStation(
      id: "shaa_fm",
      name: "Shaa FM",
      streamUrl: "https://listen.radioking.com/radio/384487/stream/435781",
      frequency: "91.1 MHz",
      primaryColor: Color(0xFFFF2525),
      secondaryColor: Color(0xFFFF8F00),
      description: "Sri Lanka's Youth Trend Broadcast",
      logoUrl: "https://www.gavixapps.com/radio/shaa-fm.png",
    ),
    const RadioStation(
      id: "sitha_fm",
      name: "Sitha FM",
      streamUrl: "https://shaincast.caster.fm:48148/listen.mp3",
      frequency: "88.8 MHz",
      primaryColor: Color(0xFF7B1FA2),
      secondaryColor: Color(0xFF311B92),
      description: "Sweet Sounds of Sinhala Broadcasting",
      logoUrl: "https://www.gavixapps.com/radio/sitha-fm.png",
    ),
    const RadioStation(
      id: "sun_fm",
      name: "Sun FM",
      streamUrl: "https://radio.lotustechnologieslk.net:2020/stream/sunfmgarden",
      frequency: "98.9 MHz",
      primaryColor: Color(0xFFF12711),
      secondaryColor: Color(0xFFF5AF19),
      description: "Sri Lanka's Ultimate English Hit Music Station",
      logoUrl: "https://www.gavixapps.com/radio/sun-fm.png",
    ),
    const RadioStation(
      id: "v_fm",
      name: "V FM",
      streamUrl: "https://dc1.serverse.com/proxy/fmlanka/stream",
      frequency: "94.3 MHz",
      primaryColor: Color(0xFF00C9FF),
      secondaryColor: Color(0xFF92FE9D),
      description: "V FM - The Voice of the People",
      logoUrl: "https://www.gavixapps.com/radio/v-fm.png",
    ),
    const RadioStation(
      id: "yes_fm",
      name: "Yes FM",
      streamUrl: "http://live.trusl.com:1150/",
      frequency: "101.0 MHz",
      primaryColor: Color(0xFFE91E63),
      secondaryColor: Color(0xFF1E3C72),
      description: "Sri Lanka's hit music and youth English radio station",
      logoUrl: "https://www.gavixapps.com/radio/yes-fm.png",
    ),
    const RadioStation(
      id: "sirasa_fm",
      name: "Sirasa FM",
      streamUrl: "http://live.trusl.com:1170/;",
      frequency: "106.5 MHz",
      primaryColor: Color(0xFFE53935),
      secondaryColor: Color(0xFFFFD54F),
      description: "Sri Lanka's popular Sinhala radio channel",
      logoUrl: "https://www.gavixapps.com/radio/sirasa-fm.png",
    ),
    const RadioStation(
      id: "shakthi_fm",
      name: "Shakthi FM",
      streamUrl: "http://live.trusl.com:1160/;",
      frequency: "102.7 MHz",
      primaryColor: Color(0xFF1565C0),
      secondaryColor: Color(0xFFEF6C00),
      description: "The premier Tamil radio station in Sri Lanka",
      logoUrl: "https://www.gavixapps.com/radio/shakthi-fm.png",
    ),
    const RadioStation(
      id: "y_fm",
      name: "Y FM",
      streamUrl: "http://live.trusl.com:1180/;",
      frequency: "92.7 MHz",
      primaryColor: Color(0xFF8E24AA),
      secondaryColor: Color(0xFF00E5FF),
      description: "Sri Lanka's trendsetting Sinhala youth station",
      logoUrl: "https://www.gavixapps.com/radio/y-fm.png",
    ),
    const RadioStation(
      id: "tnl_radio",
      name: "TNL Radio",
      streamUrl: "http://live.tnlrn.com:8010/live.mp3",
      frequency: "101.8 MHz",
      primaryColor: Color(0xFF212121),
      secondaryColor: Color(0xFFB0BEC5),
      description: "Sri Lanka's home of rock and alternative music",
      logoUrl: "https://www.gavixapps.com/radio/tnl-radio.png",
    ),
    const RadioStation(
      id: "sooriyan_fm",
      name: "Sooriyan FM",
      streamUrl: "http://sooriyanfm.asiabroadcasting.stream:7071/;",
      frequency: "103.4 MHz",
      primaryColor: Color(0xFFE65100),
      secondaryColor: Color(0xFFFFD54F),
      description: "Leading Tamil broadcasting network in Sri Lanka",
      logoUrl: "https://www.gavixapps.com/radio/sooriyan-fm.png",
    ),
    const RadioStation(
      id: "varnam_fm",
      name: "Varnam FM",
      streamUrl: "http://s3.voscast.com:8402/",
      frequency: "90.4 MHz",
      primaryColor: Color(0xFF00E676),
      secondaryColor: Color(0xFF00B0FF),
      description: "Sri Lanka's vibrant Tamil music station",
      logoUrl: "https://www.gavixapps.com/radio/varnam-fm.png",
    ),
  ];

  // Notifiers for dynamic config and loading states
  static final ValueNotifier<List<RadioStation>> stationsNotifier = ValueNotifier<List<RadioStation>>(defaultStations);
  static final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);

  // Tracks if the remote configurations loaded successfully
  static bool _hasLoadedRemote = false;

  // Getter for backward compatibility across the codebase
  static List<RadioStation> get stations => stationsNotifier.value;

  static Future<void> loadStations() async {
    // If already loaded successfully, don't reload unless forced
    if (_hasLoadedRemote) return;

    loadingNotifier.value = true;
    errorNotifier.value = null;

    try {
      final client = HttpClient();
      // Bypass SSL verification issues if any on dynamic configs
      client.badCertificateCallback = (cert, host, port) => true;
      // Allow up to 10 seconds for lookup and handshake
      client.connectionTimeout = const Duration(seconds: 10);
      
      final uri = Uri.parse('https://www.gavixapps.com/radio/config/stations.json');
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final jsonString = await response.transform(utf8.decoder).join();
        final List<dynamic> jsonList = json.decode(jsonString);
        final List<RadioStation> loaded = [];
        for (final item in jsonList) {
          loaded.add(RadioStation.fromJson(item));
        }
        if (loaded.isNotEmpty) {
          stationsNotifier.value = loaded;
          _hasLoadedRemote = true;
          errorNotifier.value = null;
          debugPrint("Successfully loaded ${loaded.length} remote stations.");
          
          // Download and cache logos in the background to serve to Android Auto
          cacheLogos();
        } else {
          errorNotifier.value = "No stations returned from configuration.";
        }
      } else {
        errorNotifier.value = "Server returned error: ${response.statusCode}";
      }
    } catch (e) {
      errorNotifier.value = "Check your internet connection and try again.";
      debugPrint("Error loading remote stations: $e");
    } finally {
      loadingNotifier.value = false;
    }
  }

  static Future<void> cacheLogos() async {
    if (stations.isEmpty) return;
    try {
      final tempDir = await getTemporaryDirectory();
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;

      for (final station in stations) {
        if (station.logoUrl == null) continue;
        
        final file = File('${tempDir.path}/${station.id}_logo.jpg');
        final uriStr = 'content://com.gavixapps.slradio.fileprovider/cache/${station.id}_logo.jpg?v=2';

        // If file already exists, just make sure permissions are granted
        if (await file.exists()) {
          try {
            const permissionChannel = MethodChannel('com.gavixapps.slradio/permissions');
            await permissionChannel.invokeMethod('grantUriPermission', {'uri': uriStr});
          } catch (_) {}
          continue;
        }

        // Otherwise, download and save it
        try {
          final request = await client.getUrl(Uri.parse(station.logoUrl!));
          final response = await request.close().timeout(const Duration(seconds: 10));
          
          if (response.statusCode == 200) {
            final builder = BytesBuilder();
            await for (final chunk in response) {
              builder.add(chunk);
            }
            final bytes = builder.takeBytes();
            await file.writeAsBytes(bytes);
            
            // Grant read Uri permission to Android Auto for this new file
            try {
              const permissionChannel = MethodChannel('com.gavixapps.slradio/permissions');
              await permissionChannel.invokeMethod('grantUriPermission', {'uri': uriStr});
            } catch (_) {}
          }
        } catch (e) {
          debugPrint("Failed to download logo for ${station.name}: $e");
        }
      }
    } catch (e) {
      debugPrint("Error caching logos: $e");
    }
  }
}
