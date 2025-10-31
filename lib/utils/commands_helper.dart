import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

class CommandsHelper {
  static String? readApiKeyFromConfig() {
    try {
      final home =
          Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
      if (home == null) return null;

      final configFile = File(path.join(home, '.pubmind', 'config.json'));
      if (!configFile.existsSync()) return null;

      final content = configFile.readAsStringSync();
      final json = (content.isNotEmpty)
          ? (content.startsWith('{') ? jsonDecode(content) : null)
          : null;

      return json?['openai_api_key'] as String?;
    } catch (e) {
      return null;
    }
  }

  static bool saveApiKeyToConfig(String key) {
    try {
      final home =
          Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
      if (home == null) return false;

      final configDir = Directory(path.join(home, '.pubmind'));
      if (!configDir.existsSync()) {
        configDir.createSync(recursive: true);
      }

      final configFile = File(path.join(configDir.path, 'config.json'));
      final config = {'openai_api_key': key};
      configFile.writeAsStringSync(jsonEncode(config));
      return true;
    } catch (e) {
      return false;
    }
  }
}
