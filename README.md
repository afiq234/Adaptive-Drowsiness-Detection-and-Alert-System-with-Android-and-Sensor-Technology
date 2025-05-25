# Adaptive Drowsiness Detection and Alert System  
### with Android and Sensor Technology

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=flutter&logoColor=white)]()
[![Firebase](https://img.shields.io/badge/Firebase-ffca28?style=for-the-badge&logo=firebase&logoColor=black)]()
[![ESP32](https://img.shields.io/badge/ESP32-Microcontroller-blue?style=for-the-badge)]()
[![Python](https://img.shields.io/badge/Python-3.x-blue.svg?style=for-the-badge&logo=python&logoColor=white)]()

## 📱 Overview

This project is an **adaptive drowsiness detection system** designed to run on Android with support from wearable **sensor-based inputs** via **ESP32**, real-time cloud connectivity, and **machine learning models**. It detects signs of drowsiness and triggers alerts using physiological signals (like heart rate), motion, and facial cues.

The system combines:

- Flutter mobile app
- Firebase cloud services
- LSTM model for heart rate classification
- Sensor-based data collection via ESP32
- Real-time WebSocket + MQTT integration

---

## 🧠 Features

- 🔄 Real-time heart rate data from ESP32
- 📡 Live communication using WebSocket/MQTT
- 📊 LSTM-based heart rate classification
- 👁️‍🗨️ Facial landmark/motion-based drowsiness cues
- 🔔 In-app and audible alerts
- ☁️ Firebase integration (Firestore, Authentication, etc.)
- 📂 Modular code: Android app, ML training, firmware all separated

---

## 📁 Project Structure

```bash
├── android/                    # Native Android folder (Flutter)
├── assets/
│   ├── *.tflite, *.onnx        # ML models
│   ├── alarm.wav               # Alert sound
├── lib/                        # Flutter Dart source code
├── training_lstm_model/
│   ├── trainingLstmModel.ipynb # LSTM training notebook
│   ├── realTimeLstm.py         # Live classification script
│   ├── *.csv, *.h5             # Preprocessed data & model
├── Esp32HeartRate/             # ESP32 microcontroller firmware
├── firebase.json, firestore.rules, etc.
├── pubspec.yaml

```

## ⚙️ Requirements
💻 Software
Flutter SDK (3.x)

Python 3.8+

Firebase CLI

Arduino IDE or PlatformIO for ESP32

```bash
pip install numpy pandas tensorflow matplotlib
```

## 🚀 Getting Started

Flutter setup

```bash
cd yolodetection/
flutter pub get
flutter run
```

Python ML Training
Navigate to training_lstm_model/ and run the notebook or script to train/evaluate the LSTM model.

ESP32

- Open Esp32HeartRate in Arduino IDE or PlatformIO

- Flash it to your ESP32 board with the correct COM port and sensor connections

## 🔒 Security Note
⚠️ Your google-services.json file and sensitive model/data files are ignored from this repo. Add your own Firebase credentials to android/app/google-services.json.

## 📜 License
This project is under the MIT License.
Feel free to use, modify, and contribute.

## 👨‍💻 Author

Fiq
