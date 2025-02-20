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

// Definição dos pinos para o alarme
#define ALARM_LED_PIN 26  // LED que indica alarme
#define BUZZER_PIN    14  // Buzzer para alarme

// Definindo os pinos I2C para o MPU6050: D35 para SDA e D34 para SCL
#define I2C_SDA 35
#define I2C_SCL 34

// Tempo para disparo do alarme: 2 horas em milissegundos
const unsigned long alarmDuration = 7200000;

// Variáveis para controle da posição
unsigned long positionStartTime = 0;
String currentPosition = "indefinido";

// Variáveis para calibração da posição inicial
float ax_ref, ay_ref, az_ref;
bool calibrado = false;

// Função para detectar a posição do paciente com base na aceleração
String detectPosition(float ax, float ay, float az) {
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

  // Configura os pinos de saída
  pinMode(ALARM_LED_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);

  // Inicializa a comunicação I2C nos pinos definidos (D35 e D34)
  Wire.begin(I2C_SDA, I2C_SCL);

  // Inicializa o MPU6050
  if (!mpu.begin()) {
    Serial.println("Falha ao inicializar o MPU6050!");
    while (1) delay(10);
  }

  // Calibração inicial: oriente o paciente a posicionar a perna corretamente (esticada e relaxada)
  Serial.println("Posicione a perna corretamente (esticada e relaxada). Calibração em 3 segundos...");
  delay(3000);

  sensors_event_t accel, gyro, temp;
  mpu.getEvent(&accel, &gyro, &temp);
  ax_ref = accel.acceleration.x;
  ay_ref = accel.acceleration.y;
  az_ref = accel.acceleration.z;
  
  Serial.println("Calibração concluída! Posição inicial registrada.");
  calibrado = true;

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

  // Configura o servidor MQTT
  client.setServer(mqtt_server, 1883);

  // Inicializa a contagem de tempo na posição
  positionStartTime = millis();
}

void loop() {
  // Garante que estamos conectados ao MQTT
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  // Leitura dos sensores do MPU6050
  sensors_event_t accel, gyro, temp;
  mpu.getEvent(&accel, &gyro, &temp);

  // Obtém os valores do acelerômetro
  float ax = accel.acceleration.x;
  float ay = accel.acceleration.y;
  float az = accel.acceleration.z;

  // Detecta a posição atual com base nos valores do acelerômetro
  String newPosition = detectPosition(ax, ay, az);

  // Se a posição detectada mudar, reinicia a contagem de tempo
  if (newPosition != currentPosition) {
    currentPosition = newPosition;
    positionStartTime = millis();
    // Desliga o alarme imediatamente ao mudar a posiç
