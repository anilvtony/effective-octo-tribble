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

  List<Map<String, dynamic>> stepHistory = [];

  int goal = 10000;
  int totalSteps = 0;
  int bestDaySteps = 0;
  int bestDayIndex = 0;

  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();

    endDate = DateTime.now();
    startDate = endDate!.subtract(const Duration(days: 6));

    loadGoal();
    loadHistory();
  }

  Future<void> loadGoal() async {

    final prefs = await SharedPreferences.getInstance();

    setState(() {
      goal = prefs.getInt("step_goal") ?? 10000;
    });

  }

  /// FIXED FUNCTION
  Future<void> loadHistory() async {

    if (startDate == null || endDate == null) return;

    final data = await StepStorage.getStepsBetweenDates(
      startDate!,
      endDate!,
    );

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
      totalSteps = total;
      bestDaySteps = maxSteps;
      bestDayIndex = maxIndex;

    });

  }

  Future<void> pickDateRange() async {

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    if (picked != null) {

      int difference = picked.end.difference(picked.start).inDays;

      if (difference > 9) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Maximum range is 10 days"),
          ),
        );

        return;
      }

      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });

      loadHistory();
    }
  }

  String formatDate(DateTime d) {

    const months = [
      "Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"
    ];

    return "${months[d.month-1]} ${d.day}";
  }

  String formatVerticalDate(String date) {
    DateTime d = DateTime.parse(date);

    const months = [
      "Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"
    ];

    // Get the correct ordinal suffix
    String suffix;
    int day = d.day;

    if (day >= 11 && day <= 13) {
      suffix = "th"; // Special case for 11th, 12th, 13th
    } else {
      switch (day % 10) {
        case 1:
          suffix = "st";
          break;
        case 2:
          suffix = "nd";
          break;
        case 3:
          suffix = "rd";
          break;
        default:
          suffix = "th";
      }
    }

    return "${months[d.month-1]} $day$suffix";
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF4F6FF),

      appBar: AppBar(
        title: const Text("Step History"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            /// DATE RANGE SELECTOR
            GestureDetector(

              onTap: pickDateRange,

              child: Container(

                padding: const EdgeInsets.all(14),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      color: Colors.black.withOpacity(0.05),
                    )
                  ],
                ),

                child: Row(

                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [

                    const Icon(Icons.date_range),

                    Text(

                      startDate == null
                          ? "Select Date Range"
                          : "${formatDate(startDate!)} - ${formatDate(endDate!)}",

                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),

                    ),

                    const Icon(Icons.arrow_drop_down),

                  ],

                ),

              ),

            ),

            const SizedBox(height: 20),

            /// SCROLL HINT
            Container(

              padding: const EdgeInsets.symmetric(vertical: 8),

              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),

              child: const Row(

                mainAxisAlignment: MainAxisAlignment.center,

                children: [

                  Icon(Icons.swipe, size: 16),

                  SizedBox(width: 8),

                  Text(
                    "Swipe horizontally to view more days",
                    style: TextStyle(fontSize: 13),
                  ),

                ],

              ),

            ),

            const SizedBox(height: 15),

            /// GRAPH CARD
            Container(

              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 15,
                    color: Colors.black.withOpacity(0.05),
                  )
                ],
              ),

              child: stepHistory.isEmpty
                  ? const Center(child: Text("No step data yet"))

                  : SingleChildScrollView(

                scrollDirection: Axis.horizontal,

                child: SizedBox(

                  width: stepHistory.length * 80,

                  height: 320,

                  child: BarChart(

                    BarChartData(

                      maxY: 15000,

                      gridData: FlGridData(
                        drawVerticalLine: false,
                      ),

                      borderData: FlBorderData(show: false),

                      barGroups:
                      List.generate(stepHistory.length, (index) {

                        int steps = stepHistory[index]["steps"];

                        bool best = index == bestDayIndex;

                        return BarChartGroupData(

                          x: index,

                          barRods: [

                            BarChartRodData(

                              toY: steps.toDouble(),

                              width: 24,

                              borderRadius: BorderRadius.circular(6),

                              gradient: LinearGradient(
                                colors: best
                                    ? [Colors.orange, Colors.red]
                                    : [Colors.blue, Colors.lightBlueAccent],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),

                            )

                          ],

                        );

                      }),

                      titlesData: FlTitlesData(

                        leftTitles: AxisTitles(

                          sideTitles: SideTitles(

                            showTitles: true,

                            reservedSize: 40,

                            getTitlesWidget: (value, meta) {

                              if (value % 5000 != 0) {
                                return const SizedBox();
                              }

                              return Text(
                                "${(value / 1000).toInt()}k",
                                style: const TextStyle(fontSize: 12),
                              );

                            },

                          ),

                        ),

                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),

                        topTitles: AxisTitles(

                          sideTitles: SideTitles(

                            showTitles: true,

                            getTitlesWidget: (value, meta) {

                              int index = value.toInt();

                              if (index >= stepHistory.length) {
                                return const SizedBox();
                              }

                              int steps = stepHistory[index]["steps"];

                              return Text(
                                steps.toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              );

                            },

                          ),

                        ),

                        bottomTitles: AxisTitles(

                          sideTitles: SideTitles(

                            showTitles: true,

                            reservedSize: 60,

                            getTitlesWidget: (value, meta) {

                              int index = value.toInt();

                              if (index >= stepHistory.length) {
                                return const SizedBox();
                              }

                              String label =
                              formatVerticalDate(stepHistory[index]["date"]);

                              return RotatedBox(
                                quarterTurns: 3,
                                child: Text(
                                  label,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              );

                            },

                          ),

                        ),

                      ),

                    ),

                  ),

                ),

              ),

            ),

            const SizedBox(height: 30),

            /// TOTAL STEPS
            Container(

              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(16),
              ),

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  const Text(
                    "Total Steps in Selected Range",
                    style: TextStyle(color: Colors.white70),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    totalSteps.toString(),
                    style: const TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                ],

              ),

            ),

            const SizedBox(height: 20),

            /// BEST DAY
            Container(

              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(16),
              ),

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  const Text(
                    "Best Walking Day",
                    style: TextStyle(color: Colors.white70),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "$bestDaySteps steps",
                    style: const TextStyle(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                ],

              ),

            ),

            const SizedBox(height: 20),

            /// INSIGHT
            Container(

              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.black.withOpacity(0.05),
                  )
                ],
              ),

              child: const Text(
                "Walking consistently improves heart health, boosts mood, and increases energy levels.",
                style: TextStyle(fontSize: 15),
              ),

            ),

          ],

        ),

      ),

    );

  }

}