import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GraphDataLayout extends StatefulWidget {
  @override
  _GraphDataLayoutState createState() => _GraphDataLayoutState();
}

class _GraphDataLayoutState extends State<GraphDataLayout> {
  List<RadarEntry> heartRateData = [];
  List<String> timeLabels = [];
  List<FlSpot> recentHeartRateData = [];

  @override
  void initState() {
    super.initState();
    fetchHeartRateData();
    fetchRecentHeartRateData();
  }

  void fetchHeartRateData() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref('collectData');
    ref.orderByChild('Time').limitToLast(50).onValue.listen((event) {
      List<RadarEntry> data = [];
      List<String> labels = [];
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        final values = snapshot.value as Map<dynamic, dynamic>;
        values.forEach((key, value) {
          if (value.containsKey('Time') && value.containsKey('HeartRate')) {
            try {
              int timestamp = value['Time'];
              double heartRate = value['HeartRate'].toDouble();
              data.add(RadarEntry(value: heartRate));
              labels.add('$timestamp s');
            } catch (e) {
              print('Error parsing data: $e');
            }
          }
        });
      }
      setState(() {
        heartRateData = data;
        timeLabels = labels;
      });
    });
  }

  void fetchRecentHeartRateData() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref('collectData');
    ref.orderByChild('Time').limitToLast(10).onValue.listen((event) {
      List<FlSpot> data = [];
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        final values = snapshot.value as Map<dynamic, dynamic>;
        final sortedValues = values.entries.toList()
          ..sort((a, b) => a.value['Time'].compareTo(b.value['Time']));

        for (var entry in sortedValues) {
          final value = entry.value;
          if (value.containsKey('Time') && value.containsKey('HeartRate')) {
            try {
              double timestamp = value['Time'].toDouble();
              double heartRate = value['HeartRate'].toDouble();
              data.add(FlSpot(timestamp, heartRate));
            } catch (e) {
              print('Error parsing data: $e');
            }
          }
        }
      }
      setState(() {
        recentHeartRateData = data;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Heart Rate Graphs'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 500,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: heartRateData.isNotEmpty && timeLabels.isNotEmpty
                    ? RadarChart(
                        RadarChartData(
                          dataSets: [
                            RadarDataSet(
                              dataEntries: heartRateData,
                              borderColor:
                                  const Color.fromARGB(255, 214, 11, 38),
                              fillColor: const Color.fromARGB(255, 214, 11, 38)
                                  .withOpacity(0.5),
                              borderWidth: 2,
                            ),
                          ],
                          radarBackgroundColor: Colors.transparent,
                          titlePositionPercentageOffset: 0.2,
                          titleTextStyle: TextStyle(fontSize: 12),
                          getTitle: (index, angle) {
                            if (index < timeLabels.length) {
                              return RadarChartTitle(
                                text: timeLabels[index],
                                angle: angle,
                              );
                            } else {
                              return RadarChartTitle(
                                text: '',
                                angle: angle,
                              );
                            }
                          },
                          tickCount: 5,
                          ticksTextStyle:
                              TextStyle(color: Colors.grey, fontSize: 10),
                          tickBorderData: BorderSide(color: Colors.grey),
                          gridBorderData: BorderSide(color: Colors.grey),
                        ),
                      )
                    : Center(child: Text('No data available')),
              ),
            ),
            Container(
              height: 500,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    width: 1000, // Adjust width as needed
                    child: recentHeartRateData.isNotEmpty
                        ? LineChart(LineChartData(
                            backgroundColor:
                                const Color.fromARGB(255, 232, 245, 252),
                            lineBarsData: [
                              LineChartBarData(
                                spots: recentHeartRateData,
                                isCurved:
                                    false, // Keep straight lines for accuracy
                                color: const Color.fromARGB(255, 214, 11, 38),
                                barWidth: 2,
                                belowBarData: BarAreaData(show: false),
                              ),
                            ],
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 32,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      '${value.toInt()}s',
                                      style: const TextStyle(fontSize: 12),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 32,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      '${value.toInt()}',
                                      style: const TextStyle(fontSize: 12),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawHorizontalLine: true,
                              getDrawingHorizontalLine: (value) => const FlLine(
                                color: Color(0xff37434d),
                                strokeWidth: 1,
                              ),
                            ),
                            minX: recentHeartRateData.isNotEmpty
                                ? recentHeartRateData
                                    .map((e) => e.x)
                                    .reduce((a, b) => a < b ? a : b)
                                : 0,
                            maxX: recentHeartRateData.isNotEmpty
                                ? recentHeartRateData
                                    .map((e) => e.x)
                                    .reduce((a, b) => a > b ? a : b)
                                : 0,
                            minY: recentHeartRateData.isNotEmpty
                                ? recentHeartRateData
                                        .map((e) => e.y)
                                        .reduce((a, b) => a < b ? a : b) -
                                    10
                                : 0,
                            maxY: recentHeartRateData.isNotEmpty
                                ? recentHeartRateData
                                        .map((e) => e.y)
                                        .reduce((a, b) => a > b ? a : b) +
                                    10
                                : 100,
                          ))
                        : Center(child: Text('No data available')),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
