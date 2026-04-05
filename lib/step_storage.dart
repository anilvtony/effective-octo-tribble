import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StepStorage {

  // ==================== CONSTANTS ====================

  // Step tracking keys
  static const String initialStepsKey = "initial_steps";
  static const String todayStepsKey = "today_steps";
  static const String lastDateKey = "last_date";

  // Goal key
  static const String stepGoalKey = "step_goal";

  // Coins system keys
  static const String coinsKey = "user_coins";
  static const String totalStepsEarnedKey = "total_steps_earned";
  static const String coinHistoryKey = "coin_history";
  static const String lastCoinMilestoneKey = "last_coin_milestone";

  // ==================== STEP TRACKING METHODS ====================

  /// Save initial sensor steps value
  static Future<void> saveInitialSteps(int steps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(initialStepsKey, steps);
  }

  /// Get initial sensor steps value
  static Future<int> getInitialSteps() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(initialStepsKey) ?? 0;
  }

  /// Save today's steps and also save to history
  static Future<void> saveTodaySteps(int steps) async {
    final prefs = await SharedPreferences.getInstance();

    String today = DateTime.now().toString().split(" ")[0];

    // Save current steps
    await prefs.setInt(todayStepsKey, steps);

    // Save for history tracking
    await prefs.setInt("steps_$today", steps);
  }

  /// Get today's steps
  static Future<int> getTodaySteps() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(todayStepsKey) ?? 0;
  }

  /// Check if it's a new day and reset if needed
  static Future<bool> isNewDay() async {
    final prefs = await SharedPreferences.getInstance();

    String today = DateTime.now().toString().split(" ")[0];
    String? lastDate = prefs.getString(lastDateKey);

    if (lastDate == null) {
      // First time opening app
      await prefs.setString(lastDateKey, today);
      return false;
    }

    if (lastDate != today) {
      // New day started
      await prefs.setString(lastDateKey, today);

      // Reset today's steps
      await prefs.setInt(todayStepsKey, 0);

      return true;
    }

    return false;
  }

  /// Get steps between two dates (inclusive)
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

  /// Get last 7 days of steps
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

  /// Get steps for a specific date
  static Future<int> getStepsForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    String key = date.toString().split(" ")[0];
    return prefs.getInt("steps_$key") ?? 0;
  }

  /// Clear all step history (use with caution)
  static Future<void> clearAllStepHistory() async {
    final prefs = await SharedPreferences.getInstance();

    // Get all keys
    Set<String> keys = prefs.getKeys();

    // Remove all step-related keys
    for (String key in keys) {
      if (key.startsWith("steps_")) {
        await prefs.remove(key);
      }
    }

    await prefs.remove(todayStepsKey);
    await prefs.remove(initialStepsKey);
  }

  // ==================== GOAL METHODS ====================

  /// Save step goal
  static Future<void> saveGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(stepGoalKey, goal);
  }

  /// Get step goal
  static Future<int> getGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(stepGoalKey) ?? 10000;
  }

  // ==================== COINS SYSTEM METHODS ====================

  /// Get all coins data (balance, history, stats)
  static Future<Map<String, dynamic>> getCoinsData() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'coins': prefs.getInt(coinsKey) ?? 0,
      'totalStepsEarned': prefs.getInt(totalStepsEarnedKey) ?? 0,
      'lastMilestone': prefs.getInt(lastCoinMilestoneKey) ?? 0,
      'history': _decodeHistory(prefs.getString(coinHistoryKey)),
    };
  }

  /// Check and award coins based on steps (every 1000 steps = 1 coin)
  /// Returns number of new coins awarded
  static Future<int> checkAndAwardCoins(int currentSteps) async {
    final prefs = await SharedPreferences.getInstance();

    int lastMilestone = prefs.getInt(lastCoinMilestoneKey) ?? 0;
    int currentCoins = prefs.getInt(coinsKey) ?? 0;
    int totalStepsEarned = prefs.getInt(totalStepsEarnedKey) ?? 0;

    // Calculate how many 1000-step milestones reached
    int currentMilestone = currentSteps ~/ 1000;

    if (currentMilestone > lastMilestone) {
      int newCoins = currentMilestone - lastMilestone;

      // Update coins
      currentCoins += newCoins;
      await prefs.setInt(coinsKey, currentCoins);

      // Update total steps tracked for coins
      totalStepsEarned = currentSteps;
      await prefs.setInt(totalStepsEarnedKey, totalStepsEarned);

      // Update last milestone
      await prefs.setInt(lastCoinMilestoneKey, currentMilestone);

      // Add to history
      await _addCoinToHistory(newCoins, currentSteps);

      return newCoins;
    }

    // Update total steps even if no new coins
    if (currentSteps > totalStepsEarned) {
      await prefs.setInt(totalStepsEarnedKey, currentSteps);
    }

    return 0;
  }

  /// Add coin earning to history
  static Future<void> _addCoinToHistory(int coinsEarned, int stepsAtTime) async {
    final prefs = await SharedPreferences.getInstance();

    List<Map<String, dynamic>> history = _decodeHistory(prefs.getString(coinHistoryKey));

    String today = DateTime.now().toString().split(" ")[0];
    int timestamp = DateTime.now().millisecondsSinceEpoch;

    // Add entry for each coin earned
    for (int i = 0; i < coinsEarned; i++) {
      history.add({
        'date': today,
        'stepsAtTime': stepsAtTime,
        'timestamp': timestamp,
      });
    }

    // Keep only last 100 entries to prevent storage issues
    if (history.length > 100) {
      history = history.sublist(history.length - 100);
    }

    await prefs.setString(coinHistoryKey, _encodeHistory(history));
  }

  /// Decode history from JSON string
  static List<Map<String, dynamic>> _decodeHistory(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Encode history to JSON string
  static String _encodeHistory(List<Map<String, dynamic>> history) {
    return jsonEncode(history);
  }

  /// Get current coin balance
  static Future<int> getCoins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(coinsKey) ?? 0;
  }

  /// Add coins manually (for rewards/purchases)
  static Future<void> addCoins(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(coinsKey) ?? 0;
    await prefs.setInt(coinsKey, current + amount);
  }

  /// Spend coins (returns true if successful, false if insufficient)
  static Future<bool> spendCoins(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(coinsKey) ?? 0;

    if (current >= amount) {
      await prefs.setInt(coinsKey, current - amount);
      return true;
    }
    return false;
  }

  /// Clear coin history
  static Future<void> clearCoinHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(coinHistoryKey);
  }

  /// Reset all coins (for testing)
  static Future<void> resetCoins() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(coinsKey);
    await prefs.remove(totalStepsEarnedKey);
    await prefs.remove(lastCoinMilestoneKey);
    await prefs.remove(coinHistoryKey);
  }

  // ==================== UTILITY METHODS ====================

  /// Get all storage statistics
  static Future<Map<String, dynamic>> getStorageStats() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'todaySteps': prefs.getInt(todayStepsKey) ?? 0,
      'initialSteps': prefs.getInt(initialStepsKey) ?? 0,
      'goal': prefs.getInt(stepGoalKey) ?? 10000,
      'coins': prefs.getInt(coinsKey) ?? 0,
      'totalStepsEarned': prefs.getInt(totalStepsEarnedKey) ?? 0,
      'lastDate': prefs.getString(lastDateKey),
      'allKeys': prefs.getKeys().toList(),
    };
  }

  /// Clear all data (factory reset)
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}