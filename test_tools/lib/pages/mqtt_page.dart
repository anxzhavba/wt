import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

class MqttPage extends StatefulWidget {
  const MqttPage({super.key});

  @override
  State<MqttPage> createState() => _MqttPageState();
}

class _MqttPageState extends State<MqttPage> {
  final _brokerController = TextEditingController(text: 'broker.hivemq.com');
  final _portController = TextEditingController(text: '1883');
  final _subscribeTopicController = TextEditingController(text: 'test/topic');
  final _publishTopicController = TextEditingController(text: 'test/topic');
  final _payloadController = TextEditingController(text: 'hello world');
  final _clientIdController = TextEditingController(text: 'flutter_iot_tool');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _useSecure = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final service = state.mqttService;
    final connected = service.connected;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField(
              _brokerController,
              'MQTT Broker',
              hintText: 'broker 地址',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _portController,
                    '端口',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(_clientIdController, 'Client ID'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(_usernameController, '用户名 (可选)'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    _passwordController,
                    '密码 (可选)',
                    obscureText: true,
                  ),
                ),
              ],
            ),
            SwitchListTile(
              title: const Text('使用 TLS/SSL'),
              value: _useSecure,
              onChanged: (value) => setState(() => _useSecure = value),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final broker = _brokerController.text.trim();
                      final port = int.tryParse(_portController.text) ?? 1883;
                      final config = MqttBrokerConfig(
                        broker: broker,
                        port: port,
                        clientId: _clientIdController.text.trim().isEmpty
                            ? 'flutter_iot_tool'
                            : _clientIdController.text.trim(),
                        username: _usernameController.text.trim().isEmpty
                            ? null
                            : _usernameController.text.trim(),
                        password: _passwordController.text.trim().isEmpty
                            ? null
                            : _passwordController.text.trim(),
                        useSecure: _useSecure,
                      );
                      await state.saveMqttBroker(config);
                      state.clearSubscribedTopics();
                      try {
                        await service.connect(
                          broker: config.broker,
                          port: config.port,
                          clientId: config.clientId,
                          username: config.username,
                          password: config.password,
                          useSecure: config.useSecure,
                        );
                        state.addLog('MQTT 已连接');
                      } catch (error) {
                        state.addLog('MQTT 连接失败: $error');
                      }
                      setState(() {});
                    },
                    child: Text(connected ? '重新连接' : '连接'),
                  ),
                ),
                const SizedBox(width: 8),
                if (connected)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await service.disconnect();
                        state.clearSubscribedTopics();
                        state.addLog('MQTT 已断开');
                        setState(() {});
                      },
                      child: const Text('断开'),
                    ),
                  ),
              ],
            ),
            const Divider(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '订阅',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            _buildTextField(_subscribeTopicController, '订阅 Topic'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: connected
                        ? () async {
                            final topic = _subscribeTopicController.text.trim();
                            if (topic.isEmpty) {
                              state.addLog('订阅主题不能为空');
                              return;
                            }
                            try {
                              await service.subscribe(topic);
                              state.addSubscribedTopic(topic);
                              state.addLog('订阅主题 $topic');
                            } catch (error) {
                              state.addLog('订阅失败: $error');
                            }
                          }
                        : null,
                    child: const Text('订阅'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '已接收消息',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      state.refreshMqttMessages();
                      state.addLog('已接收消息已刷新');
                    },
                    child: const Text('刷新消息'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.mqttMessages.isEmpty)
              const Text('尚未接收到消息。')
            else
              Column(
                children: state.mqttMessages
                    .map(
                      (message) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(message),
                        ),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '发布',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            _buildTextField(_publishTopicController, '发布 Topic'),
            const SizedBox(height: 8),
            _buildTextField(_payloadController, 'Payload', maxLines: 4),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: connected
                        ? () async {
                            final topic = _publishTopicController.text.trim();
                            if (topic.isEmpty) {
                              state.addLog('发布主题不能为空');
                              return;
                            }
                            try {
                              await service.publish(
                                topic,
                                _payloadController.text,
                              );
                              state.addLog('已发布消息');
                            } catch (error) {
                              state.addLog('发布失败: $error');
                            }
                          }
                        : null,
                    child: const Text('发布'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '已订阅主题',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            if (state.subscribedTopics.isEmpty)
              const Text('尚未订阅任何主题。')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: state.subscribedTopics
                    .map((topic) => Chip(label: Text(topic)))
                    .toList(),
              ),
            const SizedBox(height: 16),
            if (state.savedMqttBrokers.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '保存的 Broker',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: state.savedMqttBrokers
                        .map(
                          (entry) {
                            final config = AppState.parseMqttBrokerConfig(entry);
                            return ActionChip(
                              label: Text(
                                config.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onPressed: () => setState(() {
                                _brokerController.text = config.broker;
                                _portController.text = config.port.toString();
                                _clientIdController.text = config.clientId;
                                _usernameController.text = config.username ?? '';
                                _passwordController.text = config.password ?? '';
                                _useSecure = config.useSecure;
                              }),
                            );
                          }
                        )
                        .toList(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    int maxLines = 1,
    String? hintText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
