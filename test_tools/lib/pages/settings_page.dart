import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('常用配置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildSection('MQTT Brokers', state.savedMqttBrokerLabels),
            const SizedBox(height: 16),
            _buildSection('HTTP 地址', state.savedHttpUrls),
            const SizedBox(height: 16),
            _buildSection('BLE 设备', state.savedBleDevices),
            const SizedBox(height: 24),
            const Text('说明', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('1. MQTT 页面支持连接 / 订阅 / 发布。\n2. HTTP 页面支持 GET/POST/PUT/DELETE，并支持自定义 Header 和 Body。\n3. BLE 页面支持扫描、连接、服务发现、特征读写、Notify。\n4. 日志页面支持实时查看、清空与导出。'),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Text('暂无保存内容')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((entry) => Chip(label: Text(entry, overflow: TextOverflow.ellipsis))).toList(),
          ),
      ],
    );
  }
}
