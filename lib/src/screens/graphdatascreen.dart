import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GraphDataScreen extends StatefulWidget {
  const GraphDataScreen({super.key});

  @override
  State<GraphDataScreen> createState() => _GraphDataScreenState();
}

class _GraphDataScreenState extends State<GraphDataScreen> {
  final List<Color> gradientColor = [
    const Color(0xFF1EF168), // A slightly transparent green
    const Color(0xFF1F152F) // A darker shade for gradient
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Graph Data"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        height: 500,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LineChart(
            LineChartData(
              backgroundColor:
                  Colors.white, // Ensure it has a contrasting background
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    FlSpot(0, 1),
                    FlSpot(2, 2),
                    FlSpot(4, 1.5),
                    FlSpot(6, 3),
                    FlSpot(8, 2.5),
                    FlSpot(10, 4),
                  ], // Replace with your actual data
                  isCurved: true,
                  gradient: LinearGradient(colors: gradientColor),
                  barWidth: 4,
                  isStrokeCapRound: true,
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: gradientColor
                          .map((color) => color.withOpacity(0.3))
                          .toList(),
                    ),
                  ),
                ),
              ],
              titlesData: const FlTitlesData(
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),

              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                getDrawingHorizontalLine: (value) => const FlLine(
                  color: Color(0xFF37434D),
                  strokeWidth: 1,
                ),
                drawVerticalLine: false,
                getDrawingVerticalLine: (value) => const FlLine(
                  color: Color(0xFF37434D),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: const Color(0xFF37434D),
                  width: 1,
                ),
              ),
              minX: 0,
              maxX: 11,
              minY: 0,
              maxY: 6,
            ),
          ),
        ),
      ),
    );
  }
}
