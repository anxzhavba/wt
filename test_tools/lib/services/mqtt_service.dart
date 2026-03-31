import 'dart:async';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  final void Function(String) log;
  final void Function(String)? onMessage;
  final void Function(String)? onSubscribed;
  MqttServerClient? _client;
  bool connected = false;

  MqttService(this.log, {this.onMessage, this.onSubscribed});

  Future<void> connect({
    required String broker,
    required int port,
    String clientId = 'flutter_debug_tool',
    String? username,
    String? password,
    bool useSecure = false,
  }) async {
    await disconnect();
    final client = MqttServerClient(broker, clientId);
    client.port = port;
    client.logging(on: false);
    client.keepAlivePeriod = 20;
    client.secure = useSecure;
    client.onConnected = () => log('MQTT connected');
    client.onDisconnected = () => log('MQTT disconnected');
    client.onSubscribed = (topic) {
      log('MQTT subscribed: $topic');
      onSubscribed?.call(topic);
    };
    client.onUnsubscribed = (topic) => log('MQTT unsubscribed: $topic');
    client.onSubscribeFail = (topic) => log('MQTT subscribe failed: $topic');

    if (username?.isNotEmpty ?? false) {
      client.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .authenticateAs(username!, password ?? '')
          .startClean();
    } else {
      client.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean();
    }

    _client = client;

    try {
      log('MQTT connecting to $broker:$port');
      final connAck = await client.connect();
      if (connAck?.returnCode == MqttConnectReturnCode.connectionAccepted) {
        connected = true;
        log('MQTT connection accepted');
        if (client.updates != null) {
          client.updates!.listen((
            List<MqttReceivedMessage<MqttMessage>>? events,
          ) {
            if (events == null) return;
            for (final event in events) {
              final payload = event.payload as MqttPublishMessage;
              final message = MqttPublishPayload.bytesToStringAsString(
                payload.payload.message,
              );
              final fullMessage = 'Topic: ${event.topic}, Payload: $message';
              print(fullMessage);
              log('MQTT message from ${event.topic}: $message');
              onMessage?.call(fullMessage);
            }
          });
        } else {
          log('MQTT updates stream unavailable');
        }
      } else {
        connected = false;
        log('MQTT connection failed: ${connAck?.returnCode}');
        await disconnect();
      }
    } catch (error) {
      connected = false;
      log('MQTT connect error: $error');
      await disconnect();
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (_client != null) {
      try {
        _client!.disconnect();
      } catch (_) {}
    }
    _client = null;
    connected = false;
  }

  Future<void> subscribe(
    String topic, {
    MqttQos qos = MqttQos.atMostOnce,
  }) async {
    if (_client == null || !connected) {
      throw StateError('MQTT client not connected');
    }
    _client!.subscribe(topic, qos);
  }

  Future<void> publish(
    String topic,
    String payload, {
    MqttQos qos = MqttQos.atMostOnce,
  }) async {
    if (_client == null || !connected) {
      throw StateError('MQTT client not connected');
    }
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    _client!.publishMessage(topic, qos, builder.payload!);
    log('MQTT published to $topic');
  }
}
