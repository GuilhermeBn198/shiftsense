#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <math.h>  // Para sqrt e pow

// Configurações do WiFi
const char* ssid = "Starlink_CIT";
const char* password = "Ufrr@2024Cit";

// Configurações do MQTT para HiveMQ
const char* mqtt_server = "07356c1b41e34d65a6152a202151c24d.s1.eu.hivemq.cloud";
const uint16_t mqtt_port = 8883;
const char* mqtt_username = "hivemq.webclient.1740079881529";
const char* mqtt_password = "h45de%Pb.6O8aBQo>JC!";
#define MQTT_TOPIC "paciente/braco"

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

// Tempo para disparo do alarme: 20 segundos para testes (substitua por 7200000 para 2 horas)
const unsigned long alarmDuration = 20000;

// Intervalo de piscagem para LED e buzzer (em milissegundos)
const unsigned long blinkInterval = 500;

// Variáveis para controle da posição
unsigned long positionStartTime = 0;
String currentPosition = "indefinido";

// Variáveis para controle da piscagem
unsigned long lastBlinkTime = 0;
bool blinkState = false;

// Função para detectar a posição do paciente com base nos valores do acelerômetro,
// utilizando os parâmetros fixos de referência.
String detectPosition(float ax, float ay, float az) {
  // Define a tolerância (ajuste conforme necessário)
  float tol = 3.0;
  
  // Calcula a distância Euclidiana entre a leitura atual e cada referência:
  float dPraCima    = sqrt(pow(ax - 10.0, 2) + pow(ay - 0.0, 2) + pow(az - 0.0, 2));
  float dPraDireita = sqrt(pow(ax - (-1.0), 2) + pow(ay - 0.0, 2) + pow(az - 10.0, 2));
  float dPraEsquerda= sqrt(pow(ax - 3.0, 2) + pow(ay - (-9.0), 2) + pow(az - 1.0, 2));
  float dPraBaixo   = sqrt(pow(ax - (-10.0), 2) + pow(ay - 0.0, 2) + pow(az - 0.0, 2));
  float dSentado    = sqrt(pow(ax - 8.0, 2) + pow(ay - (-5.0), 2) + pow(az - 2.0, 2));

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
  if (dSentado < minDist) {
    minDist = dSentado;
    pos = "sentado";
  }
  
  // Se a menor distância for maior que a tolerância, retorna "indefinido"
  if (minDist > tol) {
    return "indefinido";
  } else {
    return pos;
  }
}

// Função para reconectar ao broker MQTT, se necessário
void reconnect() {
  while (!client.connected()) {
    Serial.print("Conectando ao MQTT...");
    String clientId = "ESP32_Braco-";
    clientId += String(random(0xffff), HEX);
    if (client.connect(clientId.c_str(), mqtt_username, mqtt_password)) {
      Serial.println(" conectado!");
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

  // Não utilizamos calibração dinâmica; usaremos os parâmetros fixos.
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

  // Inicializa a contagem de tempo na posição
  positionStartTime = millis();
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  // Leitura dos sensores do MPU6050
  sensors_event_t accel, gyro, temp;
  mpu.getEvent(&accel, &gyro, &temp);

  // Valores do acelerômetro
  float ax = accel.acceleration.x;
  float ay = accel.acceleration.y;
  float az = accel.acceleration.z;
  
  // Debug: imprime os valores do acelerômetro
  Serial.print("Acelerometro -> X: ");
  Serial.print(ax, 2);
  Serial.print("  Y: ");
  Serial.print(ay, 2);
  Serial.print("  Z: ");
  Serial.println(az, 2);
  
  // Debug: imprime os valores do giroscópio
  Serial.print("Giroscopio -> X: ");
  Serial.print(gyro.gyro.x, 2);
  Serial.print("  Y: ");
  Serial.print(gyro.gyro.y, 2);
  Serial.print("  Z: ");
  Serial.println(gyro.gyro.z, 2);

  // Detecta a posição com base nos parâmetros fixos
  String newPosition = detectPosition(ax, ay, az);

  // Se a posição mudar, reinicia a contagem
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

  // Aciona alarme piscante se o tempo na posição ultrapassar o limite
  if (currentPosition != "indefinido" && timeInPosition >= alarmDuration) {
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

  // Monta a mensagem JSON utilizando um buffer fixo
  char payload[256];
  snprintf(payload, sizeof(payload),
           "{\"position\":\"%s\",\"time_in_position\":%lu,\"ax\":%.2f,\"ay\":%.2f,\"az\":%.2f}",
           currentPosition.c_str(), timeInPosition / 1000, ax, ay, az);

  // Publica os dados no MQTT
  client.publish(MQTT_TOPIC, payload);

  delay(1000); // Atualiza a cada 1 segundo
}
