import 'package:shared_preferences/shared_preferences.dart';

class StepStorage {

  static const String initialStepsKey = "initial_steps";
  static const String todayStepsKey = "today_steps";
  static const String lastDateKey = "last_date";

  static Future<void> saveInitialSteps(int steps) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(initialStepsKey, steps);

  }

  static Future<int> getInitialSteps() async {

    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt(initialStepsKey) ?? 0;

  }

  static Future<void> saveTodaySteps(int steps) async {

    final prefs = await SharedPreferences.getInstance();

    String today = DateTime.now().toString().split(" ")[0];

    await prefs.setInt(todayStepsKey, steps);

    /// Save for history
    await prefs.setInt("steps_$today", steps);

  }

  static Future<int> getTodaySteps() async {

    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt(todayStepsKey) ?? 0;

  }

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

  /// GET STEPS BETWEEN SELECTED DATES
  static Future<List<Map<String, dynamic>>> getStepsBetweenDates(
      DateTime start,
      DateTime end,
      ) async {

    final prefs = await SharedPreferences.getInstance();

    List<Map<String, dynamic>> data = [];

    DateTime current = start;

    while (!current.isAfter(end)) {

      String dateKey = current.toString().split(" ")[0];

      int steps = prefs.getInt("steps_$dateKey") ?? 0;

      data.add({
        "date": dateKey,
        "steps": steps
      });

      current = current.add(const Duration(days: 1));

    }

    return data;

  }

  /// DEFAULT LAST 7 DAYS
  static Future<List<Map<String, dynamic>>> getLast7DaysSteps() async {

    final prefs = await SharedPreferences.getInstance();

    List<Map<String, dynamic>> data = [];

    for (int i = 6; i >= 0; i--) {

      DateTime date = DateTime.now().subtract(Duration(days: i));

      String key = date.toString().split(" ")[0];

      int steps = prefs.getInt("steps_$key") ?? 0;

      data.add({
        "date": key,
        "steps": steps
      });

    }

    return data;

  }

}