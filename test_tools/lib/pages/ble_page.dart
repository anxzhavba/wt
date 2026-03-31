import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

class BlePage extends StatefulWidget {
  const BlePage({super.key});

  @override
  State<BlePage> createState() => _BlePageState();
}

class _BlePageState extends State<BlePage> {
  final _writeController = TextEditingController(text: '010203');
  String _selectedCharacteristic = '';
  BluetoothCharacteristic? _selectedChar;
  bool _notifyEnabled = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final service = state.bleService;
    final devices = service.scanResults.values.toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: service.isScanning
                        ? null
                        : () async {
                            await service.scanDevices();
                            setState(() {});
                          },
                    child: Text(service.isScanning ? '扫描中...' : '扫描 BLE 设备'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: service.connectedDevice != null
                      ? () async {
                          await service.disconnectDevice();
                          setState(() {
                            _selectedCharacteristic = '';
                            _selectedChar = null;
                            _notifyEnabled = false;
                          });
                        }
                      : null,
                  child: const Text('断开设备'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  if (devices.isNotEmpty) ...[
                    const Text('扫描到的设备', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...devices.map((result) {
                      final name = result.device.name.isEmpty ? result.device.id.id : result.device.name;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(name),
                          subtitle: Text('RSSI ${result.rssi}'),
                          trailing: ElevatedButton(
                            onPressed: () async {
                              await state.saveBleDevice(result.device.id.id);
                              await service.connectDevice(result.device);
                              setState(() {
                                _selectedCharacteristic = '';
                                _selectedChar = null;
                                _notifyEnabled = false;
                              });
                            },
                            child: const Text('连接'),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                  if (service.connectedDevice != null) ...[
                    const SizedBox(height: 16),
                    Text('已连接设备: ${service.connectedDevice!.name.isEmpty ? service.connectedDevice!.id.id : service.connectedDevice!.name}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (service.discoveredServices.isEmpty)
                      const Text('正在发现服务...')
                    else
                      ...service.discoveredServices.map((svc) {
                        return ExpansionTile(
                          title: Text('Service ${svc.uuid}'),
                          children: svc.characteristics.map((characteristic) {
                            final id = characteristic.uuid.toString();
                            return ListTile(
                              title: Text('Characteristic $id'),
                              subtitle: Text(characteristic.properties.toString()),
                              trailing: Wrap(
                                spacing: 4,
                                children: [
                                  if (characteristic.properties.read)
                                    IconButton(
                                      icon: const Icon(Icons.remove_red_eye),
                                      tooltip: '读取',
                                      onPressed: () async {
                                        final value = await service.readCharacteristic(characteristic);
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Read: $value')));
                                      },
                                    ),
                                  if (characteristic.properties.write || characteristic.properties.writeWithoutResponse)
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      tooltip: '写入',
                                      onPressed: () {
                                        setState(() {
                                          _selectedChar = characteristic;
                                          _selectedCharacteristic = characteristic.uuid.toString();
                                        });
                                      },
                                    ),
                                  if (characteristic.properties.notify || characteristic.properties.indicate)
                                    IconButton(
                                      icon: Icon(_notifyEnabled ? Icons.notifications_active : Icons.notifications),
                                      tooltip: '通知',
                                      onPressed: () async {
                                        final enable = !_notifyEnabled;
                                        await service.toggleNotification(characteristic, enable);
                                        setState(() => _notifyEnabled = enable);
                                      },
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      }).toList(),
                  ],
                  if (_selectedChar != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    Text('写入特征 ${_selectedCharacteristic}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _writeController,
                      decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '输入十六进制数据，例如 010203'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final raw = _writeController.text.trim();
                        final bytes = _hexToBytes(raw);
                        if (bytes.isEmpty) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('无效的数据格式')));
                          return;
                        }
                        await service.writeCharacteristic(_selectedChar!, bytes, withResponse: true);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('写入成功')));
                      },
                      child: const Text('写入特征值'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (state.savedBleDevices.isNotEmpty) ...[
                    const Text('保存的 BLE 设备 ID', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: state.savedBleDevices
                          .map((deviceId) => Chip(label: Text(deviceId, overflow: TextOverflow.ellipsis)))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<int> _hexToBytes(String hex) {
    final sanitized = hex.replaceAll(' ', '').replaceAll('-', '');
    if (sanitized.length % 2 != 0) return [];
    final bytes = <int>[];
    for (var i = 0; i < sanitized.length; i += 2) {
      final part = sanitized.substring(i, i + 2);
      final value = int.tryParse(part, radix: 16);
      if (value == null) return [];
      bytes.add(value);
    }
    return bytes;
  }
}
