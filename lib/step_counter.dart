import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'goal_settings_screen.dart';
import 'step_storage.dart';

class StepCounter extends StatefulWidget {
  const StepCounter({super.key});

  @override
  State<StepCounter> createState() => _StepCounterState();
}

class _StepCounterState extends State<StepCounter> {
  int _initialSteps = 0;
  int _currentSteps = 0;
  int _goal = 10000;

  StreamSubscription<StepCount>? _stepSubscription;

  // CRITICAL: Prevent concurrent coin processing
  bool _processingCoin = false;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  /// Initialize app
  Future<void> initialize() async {
    await loadGoal();
    await loadSavedSteps();
    await checkDailyReset();
    await requestPermission();
  }

  /// Load goal from storage
  Future<void> loadGoal() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _goal = prefs.getInt("step_goal") ?? 10000;
    });
  }

  /// Reset steps if new day started
  Future<void> checkDailyReset() async {
    bool reset = await StepStorage.isNewDay();

    if (reset) {
      await StepStorage.saveInitialSteps(0);

      if (!mounted) return;

      setState(() {
        _initialSteps = 0;
        _currentSteps = 0;
      });
    }
  }

  /// Ask activity recognition permission
  Future<void> requestPermission() async {
    var status = await Permission.activityRecognition.request();

    if (status.isGranted) {
      startStepCounter();
    } else {
      debugPrint("Permission denied");
    }
  }

  /// Start step counter sensor - BUG-FIXED VERSION
  void startStepCounter() {
    _stepSubscription = Pedometer.stepCountStream.listen((StepCount event) async {

      if (_initialSteps == 0) {
        _initialSteps = event.steps;
        await StepStorage.saveInitialSteps(_initialSteps);
      }

      int todaySteps = event.steps - _initialSteps;

      // CRITICAL FIX: Prevent concurrent processing with flag
      if (!_processingCoin) {
        _processingCoin = true;

        int newCoins = await StepStorage.checkAndAwardCoins(todaySteps);

        _processingCoin = false;

        if (newCoins > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("🎉 Earned $newCoins coin${newCoins > 1 ? 's' : ''}!"),
              backgroundColor: Colors.amber,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _currentSteps = todaySteps;
      });

      await StepStorage.saveTodaySteps(todaySteps);

    }, onError: (error) {
      debugPrint("Sensor error: $error");
    });
  }

  /// Load saved steps
  Future<void> loadSavedSteps() async {
    _initialSteps = await StepStorage.getInitialSteps();

    if (!mounted) return;

    setState(() {});
  }

  /// Cancel sensor when screen closes
  @override
  void dispose() {
    _stepSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progress = (_currentSteps / _goal).clamp(0.0, 1.0);
    int percent = (progress * 100).toInt();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),

      appBar: AppBar(
        title: const Text("Step Counter"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,

        actions: [
          IconButton(
            icon: const Icon(Icons.flag),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GoalSettingsScreen(),
                ),
              );
              loadGoal();
            },
          )
        ],
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              const Text(
                "Today's Steps",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 40),

              /// Step progress circle
              Container(
                padding: const EdgeInsets.all(25),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),

                child: Stack(
                  alignment: Alignment.center,

                  children: [
                    SizedBox(
                      width: 220,
                      height: 220,

                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 14,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(Colors.blue),
                      ),
                    ),

                    Column(
                      mainAxisSize: MainAxisSize.min,

                      children: [
                        const Icon(
                          Icons.directions_walk,
                          size: 48,
                          color: Colors.blue,
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "$_currentSteps",
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const Text(
                          "steps",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "$percent% completed",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 40),

              /// Goal card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    const Icon(
                      Icons.flag,
                      color: Colors.blue,
                    ),

                    const SizedBox(width: 10),

                    Text(
                      "Goal: $_goal steps",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}