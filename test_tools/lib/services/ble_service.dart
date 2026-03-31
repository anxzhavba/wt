import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  final void Function(String) log;

  bool isScanning = false;
  final Map<DeviceIdentifier, ScanResult> scanResults = {};
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  BluetoothDevice? connectedDevice;
  List<BluetoothService> discoveredServices = [];
  final Map<String, StreamSubscription<List<int>>> notifySubscriptions = {};

  BleService(this.log);

  Stream<List<ScanResult>> get scanResultStream => FlutterBluePlus.scanResults;

  Future<void> scanDevices({Duration timeout = const Duration(seconds: 5)}) async {
    scanResults.clear();
    isScanning = true;
    log('BLE scan started');
    _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        scanResults[result.device.id] = result;
      }
    });

    try {
      await FlutterBluePlus.startScan(timeout: timeout);
      await Future<void>.delayed(timeout);
    } catch (error) {
      log('BLE scan error: $error');
    } finally {
      isScanning = false;
      await stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      log('BLE scan finished');
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
  }

  Future<void> connectDevice(BluetoothDevice device) async {
    if (connectedDevice != null) {
      await disconnectDevice();
    }
    log('BLE connecting to ${device.name.isEmpty ? device.id.id : device.name}');
    try {
      await device.connect();
      connectedDevice = device;
      log('BLE connected');
      await discoverServices(device);
    } catch (error) {
      log('BLE connect error: $error');
      rethrow;
    }
  }

  Future<void> disconnectDevice() async {
    if (connectedDevice != null) {
      try {
        await connectedDevice!.disconnect();
      } catch (_) {}
      connectedDevice = null;
      discoveredServices = [];
      await cancelAllNotifications();
      log('BLE disconnected');
    }
  }

  Future<void> discoverServices(BluetoothDevice device) async {
    try {
      discoveredServices = await device.discoverServices();
      log('BLE discovered ${discoveredServices.length} services');
    } catch (error) {
      log('BLE discover services error: $error');
    }
  }

  Future<String> readCharacteristic(BluetoothCharacteristic characteristic) async {
    try {
      final value = await characteristic.read();
      final text = value.isNotEmpty ? value.toString() : '<empty>';
      log('BLE read ${characteristic.uuid}: $text');
      return text;
    } catch (error) {
      final message = 'BLE read error: $error';
      log(message);
      rethrow;
    }
  }

  Future<void> writeCharacteristic(BluetoothCharacteristic characteristic, List<int> value,
      {bool withResponse = false}) async {
    try {
      await characteristic.write(value, withoutResponse: !withResponse);
      log('BLE wrote ${value.length} bytes to ${characteristic.uuid}');
    } catch (error) {
      log('BLE write error: $error');
      rethrow;
    }
  }

  Future<void> toggleNotification(BluetoothCharacteristic characteristic, bool enable) async {
    try {
      await characteristic.setNotifyValue(enable);
      final key = characteristic.uuid.toString();
      if (enable) {
        final subscription = characteristic.lastValueStream.listen((data) {
          log('BLE notify ${characteristic.uuid}: ${_formatBytes(data)}');
        });
        notifySubscriptions[key] = subscription;
        log('BLE notification enabled for ${characteristic.uuid}');
      } else {
        await notifySubscriptions[key]?.cancel();
        notifySubscriptions.remove(key);
        log('BLE notification disabled for ${characteristic.uuid}');
      }
    } catch (error) {
      log('BLE notify error: $error');
      rethrow;
    }
  }

  Future<void> cancelAllNotifications() async {
    for (final sub in notifySubscriptions.values) {
      await sub.cancel();
    }
    notifySubscriptions.clear();
  }

  String _formatBytes(List<int> bytes) {
    if (bytes.isEmpty) {
      return '<empty>';
    }
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(' ');
  }
}
