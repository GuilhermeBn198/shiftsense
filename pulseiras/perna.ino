#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <math.h>      // Para sqrt e pow
#include <ArduinoJson.h> // Biblioteca para parse de JSON

// Configurações do WiFi
const char* ssid = "Starlink_CIT";
const char* password = "Ufrr@2024Cit";

// Configurações do MQTT para HiveMQ
const char* mqtt_server = "07356c1b41e34d65a6152a202151c24d.s1.eu.hivemq.cloud";
const uint16_t mqtt_port = 8883;
const char* mqtt_username = "hivemq.webclient.1740079881529";
const char* mqtt_password = "h45de%Pb.6O8aBQo>JC!";

// Defina os tópicos:
// - MQTT_PUBLISH_TOPIC: tópico onde este dispositivo publica seus dados.
// - MQTT_SUBSCRIBE_TOPIC: tópico do outro dispositivo, onde ele publica seus dados.
#define MQTT_PUBLISH_TOPIC    "paciente/perna"  // Este dispositivo
#define MQTT_SUBSCRIBE_TOPIC  "paciente/braco"  // Dispositivo remoto

// Inicializa os objetos WiFi e MQTT
WiFiClientSecure espClient;
PubSubClient client(espClient);

// Inicializa o sensor MPU6050
Adafruit_MPU6050 mpu;

// Definição dos pinos
#define ALARM_LED_PIN 26  // LED que indica alarme
#define BUZZER_PIN    14  // Buzzer para alarme

// Definindo os pinos I2C para o MPU6050: D33 para SDA e D32 para SCL
#define I2C_SDA 33
#define I2C_SCL 32

// Tempo para disparo do alarme: 7200000 ms = 2 horas (para testes, pode ser 20000 ms)
const unsigned long alarmDuration = 7200000;

// Intervalo de piscagem para LED e buzzer (em milissegundos)
const unsigned long blinkInterval = 500;

// Variáveis para controle da posição
unsigned long positionStartTime = 0;
String currentPosition = "indefinido";

// Variáveis para controle da piscagem
unsigned long lastBlinkTime = 0;
bool blinkState = false;

// Variáveis para controle do alarme remoto
bool remoteAlarmActive = false;
unsigned long lastRemoteMessageTime = 0;
const unsigned long remoteTimeout = 3000; // Se não receber mensagem em 3s, desativa alarme remoto

// --- Função para detectar a posição do paciente com base nos valores do acelerômetro ---
String detectPosition(float ax, float ay, float az) {
  // Define a tolerância (ajuste conforme necessário)
  float tol = 3.0;
  
  // Calcula a distância Euclidiana entre a leitura atual e cada referência:
  float dPraCima    = sqrt(pow(ax - 10.0, 2) + pow(ay - (-0.3), 2) + pow(az - (-0.5), 2));
  float dPraBaixo   = sqrt(pow(ax - (-9.5), 2) + pow(ay - (-0.4), 2) + pow(az - 1.5, 2));
  float dPraEsquerda= sqrt(pow(ax - (-0.5), 2) + pow(ay - (-0.3), 2) + pow(az - (-9.4), 2));
  float dPraDireita = sqrt(pow(ax - 1.2, 2) + pow(ay - (-0.2), 2) + pow(az - 10.3, 2));
  
  // Inicialmente, assume a posição "pra cima"
  float minDist = dPraCima;
  String pos = "pra cima";

  if (dPraDireita < minDist) {
    minDist = dPraDireita;
    pos = "pra direita";
  }
  if (dPraEsquerda < minDist) {
    minDist = dPraEsquerda;
    pos = "pra esquerda";
  }
  if (dPraBaixo < minDist) {
    minDist = dPraBaixo;
    pos = "pra baixo";
  }
  
  // Verifica se há uma posição secundária próxima para detectar diagonais (sem repetir a principal)
  String posSecundaria = "";
  if (pos != "pra cima" && fabs(dPraCima - minDist) < tol) posSecundaria = "pra cima";
  if (pos != "pra direita" && fabs(dPraDireita - minDist) < tol) posSecundaria = "pra direita";
  if (pos != "pra esquerda" && fabs(dPraEsquerda - minDist) < tol) posSecundaria = "pra esquerda";
  if (pos != "pra baixo" && fabs(dPraBaixo - minDist) < tol) posSecundaria = "pra baixo";

  // Retorna a posição primária e, se houver, a secundária (ordenadas para consistência)
  if (!posSecundaria.isEmpty()) {
    if (pos > posSecundaria) {
      return posSecundaria + " / " + pos;
    }
    return pos + " / " + posSecundaria;
  }
  return pos;
}

// --- Função de callback do MQTT ---
void mqttCallback(char* topic, byte* payload, unsigned int length) {
  Serial.print("Mensagem recebida no tópico: ");
  Serial.println(topic);

  // Converte o payload para string
  char message[256];
  if (length >= sizeof(message)) length = sizeof(message) - 1;
  memcpy(message, payload, length);
  message[length] = '\0';
  
  Serial.print("Payload: ");
  Serial.println(message);

  // Faz o parse do JSON recebido
  StaticJsonDocument<256> doc;
  DeserializationError error = deserializeJson(doc, message);
  if (error) {
    Serial.print("Falha ao parsear JSON: ");
    Serial.println(error.c_str());
    return;
  }
  
  // Obtém o tempo na posição enviado pelo outro dispositivo (em segundos)
  unsigned long remoteTime = doc["time_in_position"];
  
  // Se o tempo exceder o limite, ativa o alarme remoto
  if (remoteTime >= alarmDuration / 1000) {
    remoteAlarmActive = true;
    Serial.println("Alarme remoto ativo!");
  } else {
    remoteAlarmActive = false;
  }
  
  // Atualiza o tempo da última mensagem recebida do dispositivo remoto
  lastRemoteMessageTime = millis();
}

// --- Função para reconectar ao broker MQTT ---
void reconnect() {
  while (!client.connected()) {
    Serial.print("Conectando ao MQTT...");
    String clientId = "ESP32_";
    clientId += String(random(0xffff), HEX);
    if (client.connect(clientId.c_str(), mqtt_username, mqtt_password)) {
      Serial.println(" conectado!");
      // Ao conectar, inscreve-se no tópico do dispositivo remoto
      client.subscribe(MQTT_SUBSCRIBE_TOPIC);
      Serial.print("Inscrito no tópico remoto: ");
      Serial.println(MQTT_SUBSCRIBE_TOPIC);
    } else {
      Serial.print(" falhou, rc=");
      Serial.print(client.state());
      Serial.println(" tentando novamente em 5 segundos");
      delay(5000);
    }
  }
}

void setup() {
  Serial.begin(115200);
  delay(100);

  // Inicializa a comunicação I2C nos pinos definidos (D33 para SDA e D32 para SCL)
  Wire.begin(I2C_SDA, I2C_SCL);
  
  // Inicializa o MPU6050
  if (!mpu.begin()) {
    Serial.println("Falha ao inicializar o MPU6050!");
    while (1) delay(10);
  }
  Serial.println("Utilizando parâmetros fixos para detecção de posição.");

  // Configuração dos pinos de saída
  pinMode(ALARM_LED_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);

  // Conecta à rede WiFi
  Serial.print("Conectando à rede WiFi: ");
  Serial.println(ssid);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("");
  Serial.print("Conectado! IP: ");
  Serial.println(WiFi.localIP());

  // Configura o cliente seguro MQTT para aceitar certificados não verificados (para testes)
  espClient.setInsecure();
  client.setServer(mqtt_server, mqtt_port);
  // Define o callback para mensagens recebidas
  client.setCallback(mqttCallback);

  // Inicializa a contagem de tempo na posição
  positionStartTime = millis();
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  // Verifica se passou tempo demais sem receber dados do dispositivo remoto
  if (millis() - lastRemoteMessageTime > remoteTimeout) {
    remoteAlarmActive = false;
  }

  // Leitura dos sensores do MPU6050
  sensors_event_t accel, gyro, temp;
  mpu.getEvent(&accel, &gyro, &temp);

  // Valores do acelerômetro
  float ax = accel.acceleration.x;
  float ay = accel.acceleration.y;
  float az = accel.acceleration.z;
  
  // Debug: imprime os valores do acelerômetro e giroscópio
  Serial.print("Acelerometro -> X: ");
  Serial.print(ax, 2);
  Serial.print("  Y: ");
  Serial.print(ay, 2);
  Serial.print("  Z: ");
  Serial.println(az, 2);
  
  Serial.print("Giroscopio -> X: ");
  Serial.print(gyro.gyro.x, 2);
  Serial.print("  Y: ");
  Serial.print(gyro.gyro.y, 2);
  Serial.print("  Z: ");
  Serial.println(gyro.gyro.z, 2);

  // Detecta a posição com base nos parâmetros fixos
  String newPosition = detectPosition(ax, ay, az);

  // Se a posição mudar, reinicia a contagem e desliga eventuais alarmes
  if (newPosition != currentPosition) {
    currentPosition = newPosition;
    positionStartTime = millis();
    digitalWrite(ALARM_LED_PIN, LOW);
    digitalWrite(BUZZER_PIN, LOW);
    Serial.print("Posição alterada: ");
    Serial.println(currentPosition);
  }

  unsigned long timeInPosition = millis() - positionStartTime;
  Serial.print("Tempo na posição ");
  Serial.print(currentPosition);
  Serial.print(": ");
  Serial.print(timeInPosition / 1000);
  Serial.println(" s");

  // Condição para acionar o alarme:
  // Se o tempo local exceder o limite OU se o outro dispositivo sinalizou alarme.
  bool localAlarmActive = (currentPosition != "indefinido" && timeInPosition >= alarmDuration);
  if (localAlarmActive || remoteAlarmActive) {
    if (millis() - lastBlinkTime >= blinkInterval) {
      blinkState = !blinkState; // alterna o estado
      lastBlinkTime = millis();
    }
    digitalWrite(ALARM_LED_PIN, blinkState ? HIGH : LOW);
    digitalWrite(BUZZER_PIN, blinkState ? HIGH : LOW);
    Serial.println("ALERTA: Posição prolongada detectada! (Piscar)");
  } else {
    digitalWrite(ALARM_LED_PIN, LOW);
    digitalWrite(BUZZER_PIN, LOW);
  }

  // Monta a mensagem JSON para publicação, incluindo a posição, tempo e leituras dos sensores.
  char payload[256];
  snprintf(payload, sizeof(payload),
           "{\"position\":\"%s\",\"time_in_position\":%lu,\"ax\":%.2f,\"ay\":%.2f,\"az\":%.2f}",
           currentPosition.c_str(), timeInPosition / 1000, ax, ay, az);

  // Publica os dados no tópico deste dispositivo
  client.publish(MQTT_PUBLISH_TOPIC, payload);

  delay(1000); // Atualiza a cada 1 segundo
}
