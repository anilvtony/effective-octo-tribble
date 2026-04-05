import 'package:flutter/material.dart';
import 'step_counter.dart';
import 'history_screen.dart';
import 'coins_screen.dart';

void main() {
  runApp(const StepApp());
}

class StepApp extends StatefulWidget {
  const StepApp({super.key});

  @override
  State<StepApp> createState() => _StepAppState();
}

class _StepAppState extends State<StepApp> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const StepCounter(),
    const HistoryScreen(),
    const CoinsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
      ),

      home: Scaffold(
        body: _screens[_currentIndex],

        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,

          onTap: (index) {
            setState(() {
              _currentIndex = index;
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

            BottomNavigationBarItem(
              icon: Icon(Icons.monetization_on),
              label: "Coins",
            ),
          ],
        ),
      ),
    );
  }
}