import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../services/ble_service.dart';
import '../services/config_service.dart';
import '../services/http_service.dart';
import '../services/mqtt_service.dart';

class MqttBrokerConfig {
  final String broker;
  final int port;
  final String clientId;
  final String? username;
  final String? password;
  final bool useSecure;

  MqttBrokerConfig({
    required this.broker,
    required this.port,
    required this.clientId,
    this.username,
    this.password,
    this.useSecure = false,
  });

  factory MqttBrokerConfig.fromJson(Map<String, dynamic> json) {
    return MqttBrokerConfig(
      broker: json['broker'] as String? ?? '',
      port: json['port'] as int? ?? 1883,
      clientId: json['clientId'] as String? ?? 'flutter_iot_tool',
      username: json['username'] as String?,
      password: json['password'] as String?,
      useSecure: json['useSecure'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'broker': broker,
      'port': port,
      'clientId': clientId,
      'username': username,
      'password': password,
      'useSecure': useSecure,
    };
  }

  String get label {
    final secureLabel = useSecure ? ' (SSL)' : '';
    return '$broker:$port [$clientId]$secureLabel';
  }
}

class AppState extends ChangeNotifier {
  final List<String> logs = [];
  final List<String> savedMqttBrokers = [];
  final List<String> savedHttpUrls = [];
  final List<String> savedBleDevices = [];
  final List<String> mqttMessages = [];
  final List<String> subscribedTopics = [];

  static MqttBrokerConfig parseMqttBrokerConfig(String entry) {
    try {
      final json = jsonDecode(entry) as Map<String, dynamic>;
      return MqttBrokerConfig.fromJson(json);
    } catch (_) {
      return MqttBrokerConfig(
        broker: entry,
        port: 1883,
        clientId: 'flutter_iot_tool',
      );
    }
  }

  List<String> get savedMqttBrokerLabels => savedMqttBrokers
      .map((entry) => parseMqttBrokerConfig(entry).label)
      .toList();

  late final ConfigService configService;
  late final MqttService mqttService;
  late final HttpService httpService;
  late final BleService bleService;

  AppState() {
    configService = ConfigService();
    mqttService = MqttService(
      _addLog,
      onMessage: _addMqttMessage,
      onSubscribed: addSubscribedTopic,
    );
    httpService = HttpService(_addLog);
    bleService = BleService(_addLog);
    _loadSavedConfigs();
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toIso8601String();
    logs.insert(0, '[$timestamp] $message');
    notifyListeners();
  }

  void _addMqttMessage(String message) {
    mqttMessages.insert(0, message);
    if (mqttMessages.length > 100) {
      mqttMessages.removeLast();
    }
    notifyListeners();
  }

  void addLog(String message) => _addLog(message);

  void addSubscribedTopic(String topic) {
    if (topic.isEmpty) return;
    if (!subscribedTopics.contains(topic)) {
      subscribedTopics.add(topic);
      notifyListeners();
    }
  }

  void clearSubscribedTopics() {
    subscribedTopics.clear();
    notifyListeners();
  }

  void clearMqttMessages() {
    mqttMessages.clear();
    notifyListeners();
  }

  void refreshMqttMessages() {
    notifyListeners();
  }

  Future<void> _loadSavedConfigs() async {
    savedMqttBrokers.clear();
    savedHttpUrls.clear();
    savedBleDevices.clear();
    savedMqttBrokers.addAll(await configService.loadSavedMqttBrokers());
    savedHttpUrls.addAll(await configService.loadSavedHttpUrls());
    savedBleDevices.addAll(await configService.loadSavedBleDevices());
    notifyListeners();
  }

  Future<void> saveMqttBroker(MqttBrokerConfig config) async {
    if (config.broker.isEmpty) return;
    final entry = jsonEncode(config.toJson());
    savedMqttBrokers.removeWhere((item) {
      final existing = parseMqttBrokerConfig(item);
      return existing.broker == config.broker &&
          existing.port == config.port &&
          existing.clientId == config.clientId;
    });
    savedMqttBrokers.insert(0, entry);
    await configService.saveMqttBrokers(savedMqttBrokers);
    notifyListeners();
  }

  Future<void> saveHttpUrl(String url) async {
    if (url.isEmpty) return;
    savedHttpUrls.remove(url);
    savedHttpUrls.insert(0, url);
    await configService.saveHttpUrls(savedHttpUrls);
    notifyListeners();
  }

  Future<void> saveBleDevice(String deviceId) async {
    if (deviceId.isEmpty) return;
    savedBleDevices.remove(deviceId);
    savedBleDevices.insert(0, deviceId);
    await configService.saveBleDevices(savedBleDevices);
    notifyListeners();
  }

  void clearLogs() {
    logs.clear();
    notifyListeners();
  }

  Future<String> exportLogs() async {
    final output = logs.reversed.join('\n');
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/debug_logs_${DateTime.now().millisecondsSinceEpoch}.txt',
    );
    await file.writeAsString(output);
    addLog('Logs exported to ${file.path}');
    return file.path;
  }
}
