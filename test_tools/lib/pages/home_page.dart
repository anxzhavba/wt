import 'package:flutter/material.dart';

import 'ble_page.dart';
import 'http_page.dart';
import 'log_page.dart';
import 'mqtt_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  static const _tabs = <Widget>[
    MqttPage(),
    HttpPage(),
    BlePage(),
    LogPage(),
    SettingsPage(),
  ];

  static const _titles = <String>['MQTT', 'HTTP', 'BLE', '日志', '设置'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('IoT 调试工具 - ${_titles[_currentIndex]}')),
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.wifi_tethering),
            label: 'MQTT',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.http), label: 'HTTP'),
          BottomNavigationBarItem(icon: Icon(Icons.bluetooth), label: 'BLE'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: '日志'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}
