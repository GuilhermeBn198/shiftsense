#include <WiFi.h>
#include <PubSubClient.h>
#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>

// Configurações do WiFi
const char* ssid = "SEU_SSID";
const char* password = "SUA_SENHA";

// Configurações do MQTT
const char* mqtt_server = "IP_DO_BROKER"; // Ex.: "192.168.1.100"
#define MQTT_TOPIC "paciente/perna"

// Inicializa os objetos WiFi e MQTT
WiFiClient espClient;
PubSubClient client(espClient);

// Inicializa o sensor MPU6050
Adafruit_MPU6050 mpu;

// Definição dos pinos
#define ALARM_LED_PIN    15  // LED que indica alarme
#define POSITION_LED_PIN 16  // LED indicador de posição válida
#define BUZZER_PIN       17  // Buzzer para alarme

// Tempo para disparo do alarme: 2 horas em milissegundos
const unsigned long alarmDuration = 7200000;

// Variáveis para controle da posição
unsigned long positionStartTime = 0;
String currentPosition = "indefinido";

// Variáveis de calibração da posição inicial
float ax_ref, ay_ref, az_ref; 
bool calibrado = false; 

// Função para detectar a posição do paciente com base na aceleração
String detectPosition(float ax, float ay, float az) {
  if (!calibrado) return "indefinido"; // Evita detecção antes da calibração

  // Cálculo de variação em relação à posição inicial
  float dx = ax - ax_ref;
  float dy = ay - ay_ref;
  float dz = az - az_ref;

  float threshold = 3.0; // Sensibilidade ajustável

  if (dx > threshold) {
    return "lado direito";
  } else if (dx < -threshold) {
    return "lado esquerdo";
  } else if (dz > threshold) {
    return "de bruços";
  } else if (dz < -threshold) {
    return "peito para cima";
  } else {
    return "indefinido";
  }
}

// Função para reconectar ao broker MQTT, se necessário
void reconnect() {
  while (!client.connected()) {
    Serial.print("Conectando ao MQTT...");
    String clientId = "ESP32_Perna-";
    clientId += String(random(0xffff), HEX);
    if (client.connect(clientId.c_str())) {
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

  pinMode(ALARM_LED_PIN, OUTPUT);
  pinMode(POSITION_LED_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);

  Wire.begin();
  if (!mpu.begin()) {
    Serial.println("Falha ao inicializar o MPU6050!");
    while (1) delay(10);
  }

  Serial.println("Posicione a perna corretamente (estendida e relaxada). Calibração em 3 segundos...");
  delay(3000);

  sensors_event_t accel, gyro, temp;
  mpu.getEvent(&accel, &gyro, &temp);
  ax_ref = accel.acceleration.x;
  ay_ref = accel.acceleration.y;
  az_ref = accel.acceleration.z;

  Serial.println("Calibração concluída! Posição inicial registrada.");
  calibrado = true;

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

  client.setServer(mqtt_server, 1883);

  positionStartTime = millis();
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  sensors_event_t accel, gyro, temp;
  mpu.getEvent(&accel, &gyro, &temp);

  float ax = accel.acceleration.x;
  float ay = accel.acceleration.y;
  float az = accel.acceleration.z;

  String newPosition = detectPosition(ax, ay, az);

  if (newPosition != currentPosition) {
    currentPosition = newPosition;
    positionStartTime = millis();
    digitalWrite(ALARM_LED_PIN, LOW);
    digitalWrite(BUZZER_PIN, LOW);
    Serial.print("Posição alterada: ");
    Serial.println(currentPosition);
  }

  unsigned long timeInPosition = millis() - positionStartTime;

  if (currentPosition != "indefinido") {
    Serial.print("Tempo na posição ");
    Serial.print(currentPosition);
    Serial.print(": ");
    Serial.print(timeInPosition / 1000);
    Serial.println(" s");

    if (timeInPosition >= alarmDuration) {
      digitalWrite(ALARM_LED_PIN, HIGH);
      digitalWrite(BUZZER_PIN, HIGH);
      Serial.println("ALERTA: Posição prolongada detectada!");
    } else {
      digitalWrite(ALARM_LED_PIN, LOW);
      digitalWrite(BUZZER_PIN, LOW);
    }
    digitalWrite(POSITION_LED_PIN, HIGH);
  } else {
    digitalWrite(ALARM_LED_PIN, LOW);
    digitalWrite(BUZZER_PIN, LOW);
    digitalWrite(POSITION_LED_PIN, LOW);
  }

  String payload = "{";
  payload += "\"position\":\"" + currentPosition + "\",";
  payload += "\"time_in_position\":" + String(timeInPosition / 1000) + ",";
  payload += "\"ax\":" + String(ax, 2) + ",";
  payload += "\"ay\":" + String(ay, 2) + ",";
  payload += "\"az\":" + String(az, 2);
  payload += "}";

  client.publish(MQTT_TOPIC, payload.c_str());

  delay(1000);
}
