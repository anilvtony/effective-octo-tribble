import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'step_storage.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {

  /// Stores last 7 days step history
  List<Map<String, dynamic>> stepHistory = [];

  /// Weekly average steps
  int weeklyAverage = 0;

  /// Best day step count
  int bestDaySteps = 0;

  /// Index of best day
  int bestDayIndex = 0;

  /// Goal steps (loaded from settings)
  int goal = 10000;

  @override
  void initState() {
    super.initState();
    loadGoal();
    loadHistory();
  }

  /// Load goal from SharedPreferences
  Future<void> loadGoal() async {

    final prefs = await SharedPreferences.getInstance();

    setState(() {
      goal = prefs.getInt("step_goal") ?? 10000;
    });

  }

  /// Load last 7 days step data
  Future<void> loadHistory() async {

    final data = await StepStorage.getLast7DaysSteps();

    int total = 0;
    int maxSteps = 0;
    int maxIndex = 0;

    for (int i = 0; i < data.length; i++) {

      int steps = data[i]["steps"];

      total += steps;

      if (steps > maxSteps) {
        maxSteps = steps;
        maxIndex = i;
      }

    }

    setState(() {

      stepHistory = data;

      weeklyAverage = data.isEmpty ? 0 : (total / data.length).round();

      bestDaySteps = maxSteps;

      bestDayIndex = maxIndex;

    });

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF2F5FF),

      appBar: AppBar(
        title: const Text("Step History"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            /// TITLE
            const Text(
              "Last 7 Days Activity",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            /// GRAPH CARD
            Container(

              padding: const EdgeInsets.all(20),

              height: 320,

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 12,
                    color: Colors.black12,
                  )
                ],
              ),

              child: stepHistory.isEmpty

              /// SHOW MESSAGE IF NO DATA
                  ? const Center(
                child: Text(
                  "No step data yet",
                  style: TextStyle(fontSize: 16),
                ),
              )

              /// BAR GRAPH
                  : BarChart(

                BarChartData(

                  alignment: BarChartAlignment.spaceAround,

                  maxY: 15000,

                  /// GOAL LINE
                  extraLinesData: ExtraLinesData(

                    horizontalLines: [

                      HorizontalLine(

                        y: goal.toDouble(),

                        color: Colors.green,

                        strokeWidth: 2,

                        dashArray: [6, 4],

                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          labelResolver: (line) => "$goal Goal",
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                      )

                    ],

                  ),

                  /// GRID
                  gridData: FlGridData(
                    drawVerticalLine: false,
                  ),

                  /// BARS
                  barGroups: List.generate(stepHistory.length, (index) {

                    int steps = stepHistory[index]["steps"];

                    bool isBestDay = index == bestDayIndex;

                    return BarChartGroupData(

                      x: index,

                      barRods: [

                        BarChartRodData(

                          toY: steps.toDouble(),

                          width: 20,

                          borderRadius: BorderRadius.circular(6),

                          /// GRADIENT BARS
                          gradient: LinearGradient(

                            colors: isBestDay
                                ? [Colors.orange, Colors.red]
                                : [Colors.blue, Colors.lightBlueAccent],

                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,

                          ),

                        )

                      ],

                    );

                  }),

                  /// TITLES
                  titlesData: FlTitlesData(

                    /// LEFT STEP VALUES
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),

                    /// HIDE RIGHT
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),

                    /// TOP STEP COUNTS
                    topTitles: AxisTitles(

                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,

                        getTitlesWidget: (value, meta) {

                          int index = value.toInt();

                          if (index >= stepHistory.length) {
                            return const SizedBox();
                          }

                          int steps = stepHistory[index]["steps"];

                          return Padding(

                            padding: const EdgeInsets.only(bottom: 4),

                            child: Text(
                              steps.toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),

                          );

                        },

                      ),

                    ),

                    /// BOTTOM DATE LABELS
                    bottomTitles: AxisTitles(

                      sideTitles: SideTitles(

                        showTitles: true,

                        reservedSize: 60,

                        getTitlesWidget: (value, meta) {

                          int index = value.toInt();

                          if (index >= stepHistory.length) {
                            return const SizedBox();
                          }

                          String date = stepHistory[index]["date"];

                          DateTime d = DateTime.parse(date);

                          const months = [
                            "Jan","Feb","Mar","Apr","May","Jun",
                            "Jul","Aug","Sep","Oct","Nov","Dec"
                          ];

                          String label =
                              "${months[d.month - 1]}-${d.day}";

                          /// VERTICAL TEXT (BOTTOM → TOP)
                          return RotatedBox(
                            quarterTurns: 3,
                            child: Text(
                              label,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );

                        },

                      ),

                    ),

                  ),

                  borderData: FlBorderData(show: false),

                ),

                /// CHART ANIMATION
                swapAnimationDuration:
                const Duration(milliseconds: 800),

                swapAnimationCurve: Curves.easeOutCubic,

              ),
            ),

            const SizedBox(height: 30),

            /// SUMMARY CARDS
            Row(

              children: [

                Expanded(
                  child: summaryCard(
                    "Weekly Avg",
                    "$weeklyAverage",
                    Icons.show_chart,
                    Colors.blue,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: summaryCard(
                    "Best Day",
                    "$bestDaySteps",
                    Icons.star,
                    Colors.orange,
                  ),
                ),

              ],

            ),

          ],

        ),

      ),

    );

  }

  /// SUMMARY CARD WIDGET
  Widget summaryCard(
      String title, String value, IconData icon, Color color) {

    return Container(

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Icon(icon, color: Colors.white),

          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

        ],

      ),

    );

  }

}