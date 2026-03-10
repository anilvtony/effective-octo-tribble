import 'package:shared_preferences/shared_preferences.dart';

class StepStorage {

  // Key used to store the initial pedometer value
  static const String initialStepsKey = "initial_steps";

  // Key used to store today's steps
  static const String todayStepsKey = "today_steps";

  // Key used to remember the last date when app ran
  static const String lastDateKey = "last_date";

  /// Save the initial pedometer value
  /// This is needed because the phone pedometer
  /// always returns total steps since boot.
  static Future<void> saveInitialSteps(int steps) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(initialStepsKey, steps);

  }

  /// Get saved initial pedometer value
  static Future<int> getInitialSteps() async {

    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt(initialStepsKey) ?? 0;

  }

  /// Save today's step count
  /// Also store it using today's date
  /// so we can show history later
  static Future<void> saveTodaySteps(int steps) async {

    final prefs = await SharedPreferences.getInstance();

    String today = DateTime.now().toString().split(" ")[0];

    // save today's steps
    await prefs.setInt(todayStepsKey, steps);

    // also save using date for history
    await prefs.setInt("steps_$today", steps);

  }

  /// Get today's step count
  static Future<int> getTodaySteps() async {

    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt(todayStepsKey) ?? 0;

  }

  /// Check if a new day has started
  /// Used to reset step counter daily
  static Future<bool> isNewDay() async {

    final prefs = await SharedPreferences.getInstance();

    String today = DateTime.now().toString().split(" ")[0];

    String? lastDate = prefs.getString(lastDateKey);

    // first time app runs
    if (lastDate == null) {

      await prefs.setString(lastDateKey, today);

      return false;

    }

    // if date changed -> new day
    if (lastDate != today) {

      await prefs.setString(lastDateKey, today);

      return true;

    }

    return false;

  }

  /// Get last 7 days step history
  /// Used for the history graph
  static Future<List<Map<String, dynamic>>> getLast7DaysSteps() async {

    final prefs = await SharedPreferences.getInstance();

    List<Map<String, dynamic>> data = [];

    // loop through last 7 days
    for (int i = 6; i >= 0; i--) {

      DateTime date = DateTime.now().subtract(Duration(days: i));

      String key = date.toString().split(" ")[0];

      // get saved steps for that day
      int steps = prefs.getInt("steps_$key") ?? 0;

      data.add({
        "date": key,
        "steps": steps
      });

    }

    return data;

  }

}