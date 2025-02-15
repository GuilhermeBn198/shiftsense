#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>

Adafruit_MPU6050 mpu;

// Definição dos pinos de saída
#define ALARM_LED_PIN 15    // LED que indica alarme
#define POSITION_LED_PIN 16 // LED que indica posição válida
#define BUZZER_PIN      17  // Buzzer para alarme

// Variáveis para controle de posição
unsigned long positionStartTime = 0;
String currentPosition = "indefinido";

// Tempo para disparar o alarme (2 horas = 7200000 ms)
const unsigned long alarmDuration = 7200000;

// Função para determinar a posição do paciente com base na aceleração
// Considerando que o sensor está posicionado no tórax do paciente:
// - Eixo X: aponta para o lado direito
// - Eixo Z: aponta para fora do peito
String detectPosition(float ax, float ay, float az) {
  float threshold = 7.0;  // Limite em m/s² (ajuste conforme necessário)

  // Verifica a direção dominante da aceleração devida à gravidade
  if (ax > threshold) {
    return "lado direito";
  } else if (ax < -threshold) {
    return "lado esquerdo";
  } else if (az > threshold) {
    return "de bruços";
  } else if (az < -threshold) {
    return "peito para cima";
  } else {
    return "indefinido";
  }
}

void setup() {
  Serial.begin(115200);
  while (!Serial)
    delay(10);

  // Inicializa as saídas
  pinMode(ALARM_LED_PIN, OUTPUT);
  pinMode(POSITION_LED_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);

  // Inicializa a comunicação I2C (padrão: SDA=21, SCL=22)
  Wire.begin();

  // Inicializa o MPU6050
  if (!mpu.begin()) {
    Serial.println("Falha ao inicializar o MPU6050!");
    while (1) {
      delay(10);
    }
  }
  Serial.println("MPU6050 iniciado com sucesso.");

  // Configura os ranges e banda de filtro
  mpu.setAccelerometerRange(MPU6050_RANGE_2_G);
  mpu.setGyroRange(MPU6050_RANGE_250_DEG);
  mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);

  // Inicializa a contagem de tempo da posição
  positionStartTime = millis();
}

void loop() {
  sensors_event_t accel, gyro, temp;
  mpu.getEvent(&accel, &gyro, &temp);

  // Lê os valores do acelerômetro
  float ax = accel.acceleration.x;
  float ay = accel.acceleration.y;
  float az = accel.acceleration.z;

  // Determina a posição atual com base nos valores de aceleração
  String newPosition = detectPosition(ax, ay, az);

  // Se a posição mudar, reinicia o contador
  if (newPosition != currentPosition) {
    currentPosition = newPosition;
    positionStartTime = millis();
    // Desliga alarme imediatamente se a posição for alterada
    digitalWrite(ALARM_LED_PIN, LOW);
    digitalWrite(BUZZER_PIN, LOW);
    Serial.print("Posição alterada: ");
    Serial.println(currentPosition);
  }

  // Se a posição for válida (uma das quatro definidas) verifica o tempo na posição
  if (currentPosition != "indefinido") {
    unsigned long timeInPosition = millis() - positionStartTime;
    // Exibe no monitor serial o tempo decorrido (em segundos)
    Serial.print("Tempo na posição ");
    Serial.print(currentPosition);
    Serial.print(": ");
    Serial.print(timeInPosition / 1000);
    Serial.println(" s");

    // Se o paciente permanecer na mesma posição por 2 horas ou mais, dispara o alarme
    if (timeInPosition >= alarmDuration) {
      digitalWrite(ALARM_LED_PIN, HIGH);
      digitalWrite(BUZZER_PIN, HIGH);
      Serial.println("ALERTA: Paciente em posição por tempo excessivo!");
    } else {
      digitalWrite(ALARM_LED_PIN, LOW);
      digitalWrite(BUZZER_PIN, LOW);
    }
  } else {
    // Se a posição for indefinida, desliga o alarme
    digitalWrite(ALARM_LED_PIN, LOW);
    digitalWrite(BUZZER_PIN, LOW);
  }

  // Opcional: LED para indicar que uma posição válida está sendo detectada
  if (currentPosition != "indefinido") {
    digitalWrite(POSITION_LED_PIN, HIGH);
  } else {
    digitalWrite(POSITION_LED_PIN, LOW);
  }

  delay(1000); // Atualiza a cada 1 segundo (para fins de debug; ajuste conforme necessário)
}
