import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart'; // reads step sensor
import 'package:permission_handler/permission_handler.dart'; // handles permissions
import 'package:shared_preferences/shared_preferences.dart';

import 'goal_settings_screen.dart';
import 'step_storage.dart';

class StepCounter extends StatefulWidget {
  const StepCounter({super.key});

  @override
  State<StepCounter> createState() => _StepCounterState();
}

class _StepCounterState extends State<StepCounter> {

  int _initialSteps = 0;   // starting sensor value
  int _currentSteps = 0;   // today's steps

  int _goal = 10000;       // default goal

  StreamSubscription<StepCount>? _stepSubscription;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  /// Initialize app
  Future<void> initialize() async {

    await loadGoal();          // load saved goal
    await loadSavedSteps();    // load previous steps
    await checkDailyReset();   // reset if new day
    await requestPermission(); // start sensor
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

  /// Start step counter sensor
  void startStepCounter() {

    _stepSubscription =
        Pedometer.stepCountStream.listen((StepCount event) async {

          // first sensor reading
          if (_initialSteps == 0) {

            _initialSteps = event.steps;

            await StepStorage.saveInitialSteps(_initialSteps);
          }

          int todaySteps = event.steps - _initialSteps;

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

  /// Manual reset
  Future<void> resetSteps() async {

    int newInitial = _initialSteps + _currentSteps;

    await StepStorage.saveInitialSteps(newInitial);
    await StepStorage.saveTodaySteps(0);

    setState(() {
      _initialSteps = newInitial;
      _currentSteps = 0;
    });
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

    return Scaffold(

      backgroundColor: const Color(0xFFF2F5FF),

      appBar: AppBar(
        title: const Text("Step Counter"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,

        /// Goal settings button
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

              // reload goal after returning
              loadGoal();
            },
          )

        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            const Text(
              "Today's Steps",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 40),

            /// Circular step progress
            Stack(
              alignment: Alignment.center,

              children: [

                /// background circle
                SizedBox(
                  width: 240,
                  height: 240,

                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 14,
                    valueColor: AlwaysStoppedAnimation(
                      Colors.grey.shade300,
                    ),
                  ),
                ),

                /// progress circle
                SizedBox(
                  width: 240,
                  height: 240,

                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 14,
                    strokeCap: StrokeCap.round,
                    valueColor:
                    const AlwaysStoppedAnimation(Colors.blue),
                  ),
                ),

                /// step number
                Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [

                    const Icon(
                      Icons.directions_walk,
                      size: 50,
                      color: Colors.blue,
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "$_currentSteps",
                      style: const TextStyle(
                        fontSize: 44,
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

                  ],
                )

              ],
            ),

            const SizedBox(height: 40),

            /// Goal text
            Text(
              "Goal: $_goal steps",
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 40),

            /// Reset button
            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton(

                onPressed: resetSteps,

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),

                child: const Text(
                  "Reset Steps",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),

              ),
            )

          ],
        ),
      ),
    );
  }
}