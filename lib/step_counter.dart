import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart'; // plugin to read step sensor
import 'package:permission_handler/permission_handler.dart'; // permission manager
import 'step_storage.dart'; // file used to store step data locally

// Main StepCounter widget
class StepCounter extends StatefulWidget {
  const StepCounter({super.key});

  @override
  State<StepCounter> createState() => _StepCounterState();
}

class _StepCounterState extends State<StepCounter> {

  int _initialSteps = 0;   // step value when app started today
  int _currentSteps = 0;   // steps counted today
  final int _goal = 10000; // daily step goal

  StreamSubscription<StepCount>? _stepSubscription; // subscription to sensor stream

  @override
  void initState() {
    super.initState();
    initialize(); // start initialization
  }

  // Initialize app
  Future<void> initialize() async {

    await loadSavedSteps();     // load previously saved steps
    await checkDailyReset();    // check if new day started
    await requestPermission();  // request activity permission
  }

  // Check if it is a new day and reset steps
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

  // Request permission to access activity sensors
  Future<void> requestPermission() async {

    var status = await Permission.activityRecognition.request();

    if (status.isGranted) {
      startStepCounter(); // start counting steps
    } else {
      debugPrint("Activity permission denied");
    }
  }

  // Start listening to pedometer sensor
  void startStepCounter() {

    _stepSubscription =
        Pedometer.stepCountStream.listen((StepCount event) async {

          // first step reading from device
          if (_initialSteps == 0) {

            _initialSteps = event.steps;

            // save starting step value
            await StepStorage.saveInitialSteps(_initialSteps);
          }

          // calculate today's steps
          int todaySteps = event.steps - _initialSteps;

          if (!mounted) return;

          // update UI
          setState(() {
            _currentSteps = todaySteps;
          });

          // save today's steps
          await StepStorage.saveTodaySteps(todaySteps);

        }, onError: (error) {

          // print error if sensor fails
          debugPrint("Step sensor error: $error");

        });
  }

  // Load previously saved step data
  Future<void> loadSavedSteps() async {

    _initialSteps = await StepStorage.getInitialSteps();

    if (!mounted) return;

    setState(() {});
  }

  // Reset button functionality
  Future<void> resetSteps() async {

    int newInitial = _initialSteps + _currentSteps;

    await StepStorage.saveInitialSteps(newInitial);
    await StepStorage.saveTodaySteps(0);

    setState(() {
      _initialSteps = newInitial;
      _currentSteps = 0;
    });
  }

  // Cancel sensor stream when screen closes
  @override
  void dispose() {

    _stepSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    // progress value for circular indicator
    double progress = (_currentSteps / _goal).clamp(0.0, 1.0);

    return Scaffold(

      backgroundColor: const Color(0xFFF2F5FF),

      appBar: AppBar(
        title: const Text("Step Counter"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // Title
            const Text(
              "Today's Steps",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 40),

            // Circular progress step indicator
            Stack(
              alignment: Alignment.center,
              children: [

                // Background circle
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

                // Progress circle
                SizedBox(
                  width: 240,
                  height: 240,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 14,
                    strokeCap: StrokeCap.round,
                    valueColor: const AlwaysStoppedAnimation(
                      Colors.blue,
                    ),
                  ),
                ),

                // Step count text
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

            // Goal text
            Text(
              "Goal: $_goal steps",
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 40),

            // Reset button
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