import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService {
  final MqttServerClient client;
  final Function(String topic, String message) onMessageReceived;
  final String username;
  final String password;

  MQTTService({
    required this.onMessageReceived,
    required String server,
    required String clientId,
    this.username = '',
    this.password = '',
    int port = 1883,
  }) : client = MqttServerClient.withPort(server, clientId, port);

  Future<void> connect() async {
    client.logging(on: true);
    client.keepAlivePeriod = 30;
    // Se a porta for 8883, habilitamos a conexão segura
    if (client.port == 8883) {
      client.secure = true;
    }
    client.setProtocolV311();

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(client.clientIdentifier)
        .startClean();
    client.connectionMessage = connMessage;

    try {
      await client.connect(username, password);
      // Se desejar, pode remover a inscrição global em '#' e gerenciar tópicos individualmente
      // client.subscribe('#', MqttQos.atMostOnce);
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final recvMsg = c[0].payload as MqttPublishMessage;
        final payload = String.fromCharCodes(recvMsg.payload.message);
        onMessageReceived(c[0].topic, payload);
      });
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
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
