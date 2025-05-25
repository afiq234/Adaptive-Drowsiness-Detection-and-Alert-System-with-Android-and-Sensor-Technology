import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:firebase_database/firebase_database.dart';

class BpmGraphPrototype extends StatefulWidget {
  final String serverUrl;

  const BpmGraphPrototype({super.key, required this.serverUrl});

  @override
  _BpmGraphStatePrototype createState() => _BpmGraphStatePrototype();
}

class _BpmGraphStatePrototype extends State<BpmGraphPrototype> {
  late WebSocketChannel _channel;
  final DatabaseReference _firebaseRef =
      FirebaseDatabase.instance.ref("heartRatePred");
  List<double> _firebaseHeartRates = [];

  @override
  void initState() {
    super.initState();
    if (GraphState.bpmData.isEmpty) {
      _initializeWebSocket();
    }
    _fetchHeartRateFromFirebase();
  }

  void _initializeWebSocket() {
    _channel = WebSocketChannel.connect(Uri.parse(widget.serverUrl));

    // Listen for messages from the server
    _channel.stream.listen((message) {
      final data = jsonDecode(message);
      if (data.containsKey('heart_rate')) {
        setState(() {
          double bpm = data['heart_rate'].toDouble();
          GraphState.time++;
          GraphState.bpmData.add(FlSpot(GraphState.time.toDouble(), bpm));

          // Limit the number of points to keep the graph manageable
          if (GraphState.bpmData.length > 50) {
            GraphState.bpmData.removeAt(0);
          }
        });
      }
    }, onError: (error) {
      print("WebSocket error: $error");
    }, onDone: () {
      print("WebSocket connection closed.");
    });
  }

  void _fetchHeartRateFromFirebase() {
    _firebaseRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        List<double> heartRates = [];

        data.forEach((key, value) {
          if (value['HeartRate'] != null) {
            try {
              double heartRate = value['HeartRate'].toDouble();
              heartRates.add(heartRate);
            } catch (e) {
              print("Error processing data: $e");
            }
          }
        });

        data.forEach((key, value) {
          if (value['HeartRate'] != null && value['Timestamp'] != null) {
            try {
              double heartRate = value['HeartRate'].toDouble();
              int timestamp = value['Timestamp'];
              DateTime dateTime =
                  DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

              // Determine the time period
              String period = _getTimePeriod(dateTime);

              // Add heart rate to the corresponding period
            } catch (e) {
              print("Error processing data: $e");
            }
          }
        });

        // Calculate maximum heart rates for each period

        setState(() {
          _firebaseHeartRates = heartRates;
        });
      }
    });
  }

  String _getTimePeriod(DateTime dateTime) {
    int hour = dateTime.hour;

    if (hour >= 6 && hour < 12) {
      return 'Morning';
    } else if (hour >= 12 && hour < 18) {
      return 'Afternoon';
    } else if (hour >= 18 && hour < 24) {
      return 'Evening';
    } else {
      return 'Night';
    }
  }

  @override
  void dispose() {
    _channel.sink.close(); // Close WebSocket connection
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double avgHeartRate = _firebaseHeartRates.isNotEmpty
        ? _firebaseHeartRates.reduce((a, b) => a + b) /
            _firebaseHeartRates.length
        : 0;
    double maxHeartRate = _firebaseHeartRates.isNotEmpty
        ? _firebaseHeartRates.reduce((a, b) => a > b ? a : b)
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Real-Time BPM Graph"),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical, // Enable vertical scrolling
        child: Column(
          children: [
            // Line Chart Section
            // Line Chart Section
            Container(
              height: 500, // Constrain height of the line chart
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal, // Enable horizontal scrolling
                child: SizedBox(
                  width: GraphState.bpmData.length > 10
                      ? GraphState.bpmData.length * 50.0
                      : MediaQuery.of(context).size.width, // Dynamic width
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.5),
                          strokeWidth: 1,
                        ),
                        drawVerticalLine: false,
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()} BPM',
                                style: const TextStyle(fontSize: 12),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}s',
                                style: const TextStyle(fontSize: 12),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: const Border(
                          left: BorderSide(color: Colors.black, width: 1),
                          bottom: BorderSide(color: Colors.black, width: 1),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: GraphState.bpmData,
                          isCurved: true, // Smooth line
                          color: Colors.blue,
                          barWidth: 3,
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                      minX: GraphState.bpmData.isNotEmpty
                          ? GraphState.bpmData
                              .map((e) => e.x)
                              .reduce((a, b) => a < b ? a : b)
                          : 0,
                      maxX: GraphState.bpmData.isNotEmpty
                          ? GraphState.bpmData
                              .map((e) => e.x)
                              .reduce((a, b) => a > b ? a : b)
                          : 10,
                      minY: GraphState.bpmData.isNotEmpty
                          ? GraphState.bpmData
                                  .map((e) => e.y)
                                  .reduce((a, b) => a < b ? a : b) -
                              10
                          : 0,
                      maxY: GraphState.bpmData.isNotEmpty
                          ? GraphState.bpmData
                                  .map((e) => e.y)
                                  .reduce((a, b) => a > b ? a : b) +
                              10
                          : 100,
                    ),
                  ),
                ),
              ),
            ),

// Radar Chart Section
            Container(
              height: 500, // Constrain height of the radar chart
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: _firebaseHeartRates.isNotEmpty
                  ? Column(
                      children: [
                        const Text(
                          "Heart Rate Statistics",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          // Constrain radar chart to available space
                          child: RadarChart(
                            RadarChartData(
                              radarBackgroundColor: Colors.transparent,
                              tickCount: 5,
                              ticksTextStyle: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                              tickBorderData:
                                  const BorderSide(color: Colors.grey),
                              gridBorderData:
                                  const BorderSide(color: Colors.grey),
                              radarBorderData:
                                  const BorderSide(color: Colors.blue),
                              dataSets: [
                                RadarDataSet(
                                  fillColor: Colors.blue.withOpacity(0.5),
                                  borderColor: Colors.blue,
                                  borderWidth: 2,
                                  entryRadius: 3,
                                  dataEntries: [
                                    RadarEntry(
                                        value: _firebaseHeartRates.reduce(
                                            (a, b) => a < b ? a : b)), // Min
                                    RadarEntry(
                                        value: _firebaseHeartRates.reduce(
                                            (a, b) => a > b ? a : b)), // Max
                                    RadarEntry(
                                        value: _firebaseHeartRates
                                                .reduce((a, b) => a + b) /
                                            _firebaseHeartRates
                                                .length), // Average
                                  ],
                                ),
                              ],
                              getTitle: (index, angle) {
                                const titles = ['Min', 'Max', 'Average'];
                                return RadarChartTitle(
                                  text: titles[index],
                                  angle: angle,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: Text(
                        "Fetching data...",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class GraphState {
  static final List<FlSpot> bpmData = [];
  static int time = 0; // Keeps track of time for X-axis
}
