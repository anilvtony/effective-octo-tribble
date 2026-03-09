import 'package:shared_preferences/shared_preferences.dart';

class StepStorage {

  static const String initialStepsKey = "initial_steps";
  static const String todayStepsKey = "today_steps";
  static const String lastDateKey = "last_date";

  // Save initial step value
  static Future<void> saveInitialSteps(int steps) async {

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(initialStepsKey, steps);

  }

  // Get initial step value
  static Future<int> getInitialSteps() async {

    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(initialStepsKey) ?? 0;

  }

  // Save today's steps
  static Future<void> saveTodaySteps(int steps) async {

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(todayStepsKey, steps);

  }

  // Get today's steps
  static Future<int> getTodaySteps() async {

    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(todayStepsKey) ?? 0;

  }

  // Check if it is a new day
  static Future<bool> isNewDay() async {

    final prefs = await SharedPreferences.getInstance();

    String today = DateTime.now().toString().split(" ")[0];

    String? lastDate = prefs.getString(lastDateKey);

    if (lastDate == null) {

      await prefs.setString(lastDateKey, today);
      return false;

    }

    if (lastDate != today) {

      await prefs.setString(lastDateKey, today);
      return true;

    }

    return false;
  }

}