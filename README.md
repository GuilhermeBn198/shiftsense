# Monitoramento de Posições para Prevenção de Úlceras de Pressão

## 📌 Sobre o Projeto  

Este projeto consiste em um **sistema IoT** para monitoramento contínuo da posição de pacientes acamados, prevenindo o desenvolvimento de **úlceras de pressão**. Ele utiliza **dois sensores ESP32** (acoplados ao braço e à perna do paciente) para coletar dados de movimento e inclinação, analisando a necessidade de mudança de posição. Caso o paciente permaneça na mesma posição por um período prolongado, o sistema emite alertas via **buzzer/motor vibratório e LED** e envia notificações automáticas para enfermeiros através de um **aplicativo Flutter**.  

## 🚀 Tecnologias Utilizadas  

- **Hardware:** ESP32, MPU6050 (Acelerômetro + Giroscópio), motor vibratório/buzzer, LED  
- **Comunicação:** Protocolo MQTT para envio de dados  
- **Software:** Aplicativo desenvolvido em Flutter  
- **Servidor:** Backend para processamento e armazenamento dos dados recebidos  

## 📡 Arquitetura do Sistema  

1. **Módulos Sensores:** Dois dispositivos ESP32 coletam dados do paciente (braço e perna).  
2. **Análise de Dados:** Integração dos dados de ambos os módulos para identificar períodos prolongados na mesma posição.  
3. **Alertas Locais:** Ativação de **buzzer/motor vibratório e LED** para alertar o paciente.  
4. **Envio de Dados:** Comunicação via **MQTT** para um servidor central.  
5. **Aplicativo para Enfermeiros:** Exibe tempo desde a última mudança de posição e notifica sobre necessidade de movimentação.  

## 📋 Funcionalidades  

✅ Monitoramento contínuo da posição do paciente  
✅ Detecção de períodos prolongados na mesma posição  
✅ Alertas visuais e sonoros para o paciente  
✅ Notificações automáticas para enfermeiros  
✅ Integração de dados de dois módulos para maior precisão  
✅ Aplicativo intuitivo para acompanhamento  

## 🔧 Requisitos  

- Placa ESP32  
- Sensores MPU6050  
- Servidor MQTT configurado  
- Flutter instalado para execução do aplicativo  

## 🔨 Configuração do ESP32

- Instale as bibliotecas necessárias (ESP32, MPU6050, PubSubClient).
- Configure a rede Wi-Fi e o servidor MQTT no código-fonte.
- Compile e envie o código para os dois ESP32.
- 📱 Executando o Aplicativo Flutter
- Instale o Flutter em sua máquina.
- Navegue até a pasta do app e execute:

```sh
flutter pub get
flutter run
```

## 🛠 Melhorias Futuras

🔹 Integração com banco de dados para análise histórica de movimentação
🔹 Aprimoramento da interface do aplicativo
🔹 Uso de IA para prever padrões de movimentação

## 🤝 Contribuindo

Fique à vontade para contribuir! Faça um fork do repositório, crie um branch e envie um pull request.

## 📄 Licença

Este projeto está sob a licença MIT.
