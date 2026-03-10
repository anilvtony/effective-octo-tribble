import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoalSettingsScreen extends StatefulWidget {
  const GoalSettingsScreen({super.key});

  @override
  State<GoalSettingsScreen> createState() => _GoalSettingsScreenState();
}

class _GoalSettingsScreenState extends State<GoalSettingsScreen> {

  // Text controller for input
  final TextEditingController goalController = TextEditingController();

  // Default goal
  int goal = 10000;

  @override
  void initState() {
    super.initState();
    loadGoal();
  }

  /// Load saved goal from storage
  Future<void> loadGoal() async {

    final prefs = await SharedPreferences.getInstance();

    setState(() {
      goal = prefs.getInt("step_goal") ?? 10000;
      goalController.text = goal.toString();
    });

  }

  /// Save goal to storage
  Future<void> saveGoal() async {

    final prefs = await SharedPreferences.getInstance();

    int newGoal = int.tryParse(goalController.text) ?? 10000;

    await prefs.setInt("step_goal", newGoal);

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Goal updated successfully"),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF2F5FF),

      appBar: AppBar(
        title: const Text("Edit Step Goal"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(
              "Daily Step Goal",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Set how many steps you want to walk daily",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 30),

            /// Goal input box
            TextField(

              controller: goalController,

              keyboardType: TextInputType.number,

              decoration: InputDecoration(

                labelText: "Step Goal",

                prefixIcon: const Icon(Icons.flag),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),

              ),

            ),

            const SizedBox(height: 30),

            /// Save button
            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton(

                onPressed: saveGoal,

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                child: const Text(
                  "Save Goal",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),

              ),
            ),

            const SizedBox(height: 20),

            /// Suggestion text
            const Text(
              "Recommended goal: 10,000 steps per day 🚶",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

          ],
        ),
      ),
    );
  }
}