#include <Wire.h> //essa biblioteca ja define como padrao do MPU sda e scl, no pino 21 e 22 respectivamente
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>

Adafruit_MPU6050 mpu;

#define LED1 15
#define LED2 16
#define BUZZER 17

void setup() {
    Serial.begin(115200);
    Wire.begin();

    pinMode(LED1, OUTPUT);
    pinMode(LED2, OUTPUT);
    pinMode(BUZZER, OUTPUT);

    if (!mpu.begin()) {
        Serial.println("Falha ao inicializar o MPU6050!");
        while (1);
    }
    Serial.println("MPU6050 iniciado com sucesso.");

    mpu.setAccelerometerRange(MPU6050_RANGE_2_G);
    mpu.setGyroRange(MPU6050_RANGE_250_DEG);
    mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
}

void loop() {
    sensors_event_t acc, gyro, temp;
    mpu.getEvent(&acc, &gyro, &temp);

    // Definir limites para ativação do buzzer e LEDs
    float accThreshold = 9.8;  // Aproximadamente 1G
    float gyroThreshold = 100; // Limite de rotação em graus/s

    // Se a aceleração em qualquer eixo ultrapassar o limite, ativa buzzer e LED1
    if (abs(acc.acceleration.x) > accThreshold || abs(acc.acceleration.y) > accThreshold || abs(acc.acceleration.z) > accThreshold) {
        digitalWrite(LED1, HIGH);
        digitalWrite(BUZZER, HIGH);
    } else {
        digitalWrite(LED1, LOW);
        digitalWrite(BUZZER, LOW);
    }

    // Se a rotação ultrapassar o limite, ativa LED2
    if (abs(gyro.gyro.x) > gyroThreshold || abs(gyro.gyro.y) > gyroThreshold || abs(gyro.gyro.z) > gyroThreshold) {
        digitalWrite(LED2, HIGH);
    } else {
        digitalWrite(LED2, LOW);
    }

    // Mostrar valores no monitor serial
    Serial.print("Accel X: "); Serial.print(acc.acceleration.x);
    Serial.print(" | Accel Y: "); Serial.print(acc.acceleration.y);
    Serial.print(" | Accel Z: "); Serial.println(acc.acceleration.z);

    Serial.print("Gyro X: "); Serial.print(gyro.gyro.x);
    Serial.print(" | Gyro Y: "); Serial.print(gyro.gyro.y);
    Serial.print(" | Gyro Z: "); Serial.println(gyro.gyro.z);

    delay(100);
}
