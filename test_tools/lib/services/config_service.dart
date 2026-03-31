import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static const _mqttKey = 'saved_mqtt_brokers';
  static const _httpKey = 'saved_http_urls';
  static const _bleKey = 'saved_ble_devices';

  Future<SharedPreferences> _prefs() async {
    return SharedPreferences.getInstance();
  }

  Future<List<String>> loadSavedMqttBrokers() async {
    final prefs = await _prefs();
    return prefs.getStringList(_mqttKey) ?? <String>[];
  }

  Future<List<String>> loadSavedHttpUrls() async {
    final prefs = await _prefs();
    return prefs.getStringList(_httpKey) ?? <String>[];
  }

  Future<List<String>> loadSavedBleDevices() async {
    final prefs = await _prefs();
    return prefs.getStringList(_bleKey) ?? <String>[];
  }

  Future<void> saveMqttBrokers(List<String> brokers) async {
    final prefs = await _prefs();
    await prefs.setStringList(_mqttKey, brokers);
  }

  Future<void> saveHttpUrls(List<String> urls) async {
    final prefs = await _prefs();
    await prefs.setStringList(_httpKey, urls);
  }

  Future<void> saveBleDevices(List<String> devices) async {
    final prefs = await _prefs();
    await prefs.setStringList(_bleKey, devices);
  }
}
