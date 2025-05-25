import serial
import time
import numpy as np
import asyncio
import websockets
from collections import deque
from tensorflow.keras.models import load_model

# Define serial port and baud rate
arduino_port = "COM9"  # Replace with your Arduino port
baud_rate = 9600
sequence_length = 10  # Sequence length for LSTM
window = deque(maxlen=sequence_length)  # Temporary storage for LSTM input
real_time_data = deque(maxlen=50)  # Data for real-time visualization

# Load the trained LSTM model (optional)
try:
    model = load_model("lstm_heart_rate_model.h5")
    print("LSTM model loaded successfully.")
    use_lstm = True
except Exception as e:
    print(f"LSTM model could not be loaded: {e}")
    use_lstm = False

# Connect to Arduino
try:
    arduino = serial.Serial(arduino_port, baud_rate, timeout=1)
    time.sleep(2)  # Allow time for connection to establish
    print("Connected to Arduino. Reading data...")
except serial.SerialException as e:
    print(f"Error: Could not open port {arduino_port}. Details: {e}")
    exit(1)

# Define thresholds and parameters for drowsiness detection
LOW_HEART_RATE_THRESHOLD = 60
DROWSY_ALERT_COUNT = 3
alert_count = 0

# WebSocket server
async def send_data(websocket, path):
    global alert_count
    while True:
        if arduino.in_waiting > 0:
            data = arduino.readline().decode("utf-8").strip()
            try:
                heart_rate = int(data)
                real_time_data.append(heart_rate)
                window.append(heart_rate)

                # Drowsiness Detection
                if heart_rate < LOW_HEART_RATE_THRESHOLD:
                    alert_count += 1
                    if alert_count >= DROWSY_ALERT_COUNT:
                        await websocket.send(
                            "ALERT: User may be drowsy! Heart Rate is consistently low."
                        )
                else:
                    alert_count = 0

                # Predict with LSTM if the window is ready
                prediction = None
                if use_lstm and len(window) == sequence_length:
                    input_sequence = np.array(window).reshape((1, sequence_length, 1))
                    prediction = model.predict(input_sequence)[0][0]
                    await websocket.send(
                        f"Real-time Heart Rate: {heart_rate} BPM | Predicted Next Value: {prediction:.2f} BPM"
                    )
                else:
                    await websocket.send(f"Real-time Heart Rate: {heart_rate} BPM")
            except ValueError:
                await websocket.send(f"Invalid data received: {data}")

# Start WebSocket server
async def main():
    async with websockets.serve(send_data, "0.0.0.0", 5000):
        await asyncio.Future()  # Run forever

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("Stopping WebSocket server.")
        arduino.close()
        print("Serial connection closed.")
