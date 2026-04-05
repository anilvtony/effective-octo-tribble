import 'package:flutter/material.dart';
import 'step_counter.dart';   // step counter screen
import 'history_screen.dart'; // history screen file
import 'coins_screen.dart';   // NEW: coins screen

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

  // list of screens for navigation - ADDED CoinsScreen
  final List<Widget> _screens = [
    const StepCounter(),
    const HistoryScreen(),
    const CoinsScreen(),  // NEW
  ];

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
      ),

      home: Scaffold(

        // display screen based on selected tab
        body: _screens[_currentIndex],

        // bottom navigation bar - ADDED Coins tab
        bottomNavigationBar: BottomNavigationBar(

          currentIndex: _currentIndex,

          // when user taps a tab
          onTap: (index) {
            setState(() {
              _currentIndex = index; // change screen
            });
          },

          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,

          items: const [

            BottomNavigationBarItem(
              icon: Icon(Icons.directions_walk),
              label: "Steps",
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: "History",
            ),

            BottomNavigationBarItem(  // NEW
              icon: Icon(Icons.monetization_on),
              label: "Coins",
            ),

          ],
        ),
      ),
    );
  }
}