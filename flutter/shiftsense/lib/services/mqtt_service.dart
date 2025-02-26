import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService {
  final MqttServerClient client;
  final Function(String topic, String message) onMessageReceived;

  MQTTService({
    required this.onMessageReceived,
    required String server,
    required String clientId,
  }) : client = MqttServerClient(server, clientId);

  Future<void> connect() async {
    client.logging(on: true);
    client.keepAlivePeriod = 30;
    
    final connMessage = MqttConnectMessage()
        .withWillTopic('willtopic')
        .startClean();
    
    client.connectionMessage = connMessage;

    try {
      await client.connect();
      client.subscribe('#', MqttQos.atMostOnce);
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