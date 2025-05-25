#include <WiFi.h>
#include <WebSocketsClient.h>

// WiFi credentials
const char* ssid = "";
const char* password = "";
const char* websocket_server = "";
const int websocket_port = ;

// Initialize WebSocket client
WebSocketsClient webSocket;

// Sensor pin configuration
const int sensorPin = 34;  // ESP32 analog pin connected to the heart rate sensor

void setup() {
  Serial.begin(115200);

  // Connect to WiFi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected!");
  Serial.print("ESP32 IP Address: ");
  Serial.println(WiFi.localIP());

  // Connect to WebSocket server
  webSocket.begin(websocket_server, websocket_port, "/");
  webSocket.onEvent(webSocketEvent);

  // Wait for WebSocket connection
  unsigned long startTime = millis();
  while (!webSocket.isConnected() && millis() - startTime < 10000) { // 10-second timeout
    webSocket.loop();
    delay(100);
  }

  if (webSocket.isConnected()) {
    Serial.println("WebSocket connection established.");
  } else {
    Serial.println("WebSocket connection failed!");
  }
}

void loop() {
  webSocket.loop();

  if (webSocket.isConnected()) {
    // Read heart rate sensor data
    int rawValue = analogRead(sensorPin);  // Read the analog value from the sensor
    int heartRate = map(rawValue, 0, 4095, 50, 150);  // Map to realistic heart rate range (adjust as needed)

    // Debug: Print raw sensor value and mapped heart rate
    Serial.print("Raw Sensor Value: ");
    Serial.print(rawValue);
    Serial.print(" | Heart Rate: ");
    Serial.println(heartRate);

    // Create JSON payload with the heart rate data
    String payload = "{\"heart_rate\": " + String(heartRate) + ", \"timestamp\": " + String(millis() / 1000) + "}";
    Serial.println("Sending: " + payload);

    // Send data via WebSocket
    bool success = webSocket.sendTXT(payload);
    if (success) {
      Serial.println("Data sent successfully.");
    } else {
      Serial.println("Failed to send data.");
    }
  }

  delay(2000);  // Adjust the delay for your sensor's sampling rate
}

void webSocketEvent(WStype_t type, uint8_t* payload, size_t length) {
  switch (type) {
    case WStype_DISCONNECTED:
      Serial.println("WebSocket disconnected.");
      break;
    case WStype_CONNECTED:
      Serial.println("WebSocket connected!");
      break;
    case WStype_TEXT:
      Serial.print("Received from server: ");
      Serial.println((char*)payload);
      break;
    default:
      Serial.println("Unhandled WebSocket event.");
      break;
  }
}
