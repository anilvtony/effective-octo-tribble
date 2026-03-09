import 'package:flutter/material.dart';
import 'step_counter.dart';   // step counter screen
import 'history_screen.dart'; // history screen file

void main() {
  runApp(const StepApp()); // start the app
}

// Main App Widget
class StepApp extends StatefulWidget {
  const StepApp({super.key});

  @override
  State<StepApp> createState() => _StepAppState();
}

class _StepAppState extends State<StepApp> {

  // keeps track of selected bottom navigation tab
  int _currentIndex = 0;

  // list of screens for navigation
  final List<Widget> _screens = [
    const StepCounter(),
    const HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      home: Scaffold(

        // display screen based on selected tab
        body: _screens[_currentIndex],

        // bottom navigation bar
        bottomNavigationBar: BottomNavigationBar(

          currentIndex: _currentIndex,

          // when user taps a tab
          onTap: (index) {
            setState(() {
              _currentIndex = index; // change screen
            });
          },

          items: const [

            BottomNavigationBarItem(
              icon: Icon(Icons.directions_walk),
              label: "StepCounts",
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: "History",
            ),

          ],
        ),
      ),
    );
  }
}