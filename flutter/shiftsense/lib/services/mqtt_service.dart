import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService {
  late MqttServerClient client;
  final Function(String topic, String message) onMessageReceived;
  final String server;
  final String clientId;
  final String username;
  final String password;
  final int port;

  MQTTService({
    required this.onMessageReceived,
    required this.server,
    required this.clientId,
    required this.username,
    required this.password,
    required this.port,
  });

  Future<void> connect() async {
    client = MqttServerClient.withPort(server, clientId, port);
    client.logging(on: true);
    client.keepAlivePeriod = 30;
    client.secure = true;
    client.securityContext = SecurityContext.defaultContext;

    // Corrigindo a mensagem de conexão
    final connMessage = MqttConnectMessage()
        .authenticateAs(username, password)
        .withClientIdentifier(clientId)
        .startClean(); // Removido withWillTopic não essencial

    // Configuração adicional para evitar nulls
    client.connectionMessage = connMessage;
    client.autoReconnect = true;

    try {
      await client.connect();
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final recvMsg = c[0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(recvMsg.payload.message);
        print("Payload recebido: $payload");
        onMessageReceived(c[0].topic, payload);
      });
    } catch (e) {
      print('Erro de conexão: $e');
      client.disconnect();
      rethrow;
    }
  }

  void subscribe(String topic) {
    client.subscribe(topic, MqttQos.atMostOnce);
  }

  void unsubscribe(String topic) {
    client.unsubscribe(topic);
  }

  void disconnect() {
    client.disconnect();
  }
}
