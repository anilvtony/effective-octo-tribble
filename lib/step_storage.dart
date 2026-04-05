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

  // 🆕 NEW: Daily limit keys
  static const String dailyCoinsEarnedKey = "daily_coins_earned";
  static const String dailyCoinsDateKey = "daily_coins_date";
  static const int maxDailyCoins = 500; // Max 500 coins per day

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
      await prefs.setString(lastDateKey, today);
      // 🆕 Reset daily coins on first use
      await prefs.setString(dailyCoinsDateKey, today);
      await prefs.setInt(dailyCoinsEarnedKey, 0);
      return false;
    }

    if (lastDate != today) {
      await prefs.setString(lastDateKey, today);
      await prefs.setInt(todayStepsKey, 0);
      // 🆕 Reset daily coins on new day
      await prefs.setString(dailyCoinsDateKey, today);
      await prefs.setInt(dailyCoinsEarnedKey, 0);
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

  /// Clear all step history
  static Future<void> clearAllStepHistory() async {
    final prefs = await SharedPreferences.getInstance();
    Set<String> keys = prefs.getKeys();

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

  // CRITICAL: Prevent duplicate processing
  static int _lastProcessedSteps = -1;
  static int _cachedLastMilestone = -1;

  /// 🆕 NEW: Get daily coins info
  static Future<Map<String, dynamic>> getDailyCoinsInfo() async {
    final prefs = await SharedPreferences.getInstance();

    String today = DateTime.now().toString().split(" ")[0];
    String? savedDate = prefs.getString(dailyCoinsDateKey);
    int dailyEarned = prefs.getInt(dailyCoinsEarnedKey) ?? 0;

    // Reset if new day
    if (savedDate != today) {
      await prefs.setString(dailyCoinsDateKey, today);
      await prefs.setInt(dailyCoinsEarnedKey, 0);
      dailyEarned = 0;
    }

    return {
      'dailyEarned': dailyEarned,
      'maxDaily': maxDailyCoins,
      'remaining': maxDailyCoins - dailyEarned,
      'canEarnMore': dailyEarned < maxDailyCoins,
    };
  }

  /// Get all coins data
  static Future<Map<String, dynamic>> getCoinsData() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'coins': prefs.getInt(coinsKey) ?? 0,
      'totalStepsEarned': prefs.getInt(totalStepsEarnedKey) ?? 0,
      'lastMilestone': prefs.getInt(lastCoinMilestoneKey) ?? 0,
      'history': _decodeHistory(prefs.getString(coinHistoryKey)),
      // 🆕 Include daily limit info
      'dailyInfo': await getDailyCoinsInfo(),
    };
  }

  /// Check and award coins - WITH DAILY LIMIT
  static Future<int> checkAndAwardCoins(int currentSteps) async {
    final prefs = await SharedPreferences.getInstance();

    // CRITICAL FIX 1: Prevent processing same steps twice
    if (currentSteps == _lastProcessedSteps) {
      return 0;
    }
    _lastProcessedSteps = currentSteps;

    // 🆕 Check daily limit first
    String today = DateTime.now().toString().split(" ")[0];
    String? savedDate = prefs.getString(dailyCoinsDateKey);
    int dailyEarned = prefs.getInt(dailyCoinsEarnedKey) ?? 0;

    // Reset if new day
    if (savedDate != today) {
      await prefs.setString(dailyCoinsDateKey, today);
      await prefs.setInt(dailyCoinsEarnedKey, 0);
      dailyEarned = 0;
    }

    // 🆕 Check if daily limit reached
    if (dailyEarned >= maxDailyCoins) {
      return -1; // Signal that daily limit is reached
    }

    // CRITICAL FIX 2: Use cache if available, else load from storage
    int lastMilestone;
    if (_cachedLastMilestone >= 0) {
      lastMilestone = _cachedLastMilestone;
    } else {
      lastMilestone = prefs.getInt(lastCoinMilestoneKey) ?? 0;
    }

    int currentCoins = prefs.getInt(coinsKey) ?? 0;
    int currentMilestone = (currentSteps ~/ 10).toInt();

    // Only award if we crossed a NEW milestone
    if (currentMilestone > lastMilestone) {
      int newCoins = currentMilestone - lastMilestone;

      // 🆕 Apply daily limit cap
      int remainingDaily = maxDailyCoins - dailyEarned;
      if (newCoins > remainingDaily) {
        newCoins = remainingDaily; // Cap at remaining daily allowance
      }

      // Update cache immediately
      _cachedLastMilestone = currentMilestone;

      // Update storage
      await prefs.setInt(coinsKey, currentCoins + newCoins);
      await prefs.setInt(lastCoinMilestoneKey, currentMilestone);
      await prefs.setInt(totalStepsEarnedKey, currentSteps);

      // 🆕 Update daily earned
      await prefs.setInt(dailyCoinsEarnedKey, dailyEarned + newCoins);

      // Add to history
      await _addCoinToHistory(newCoins, currentSteps);

      return newCoins;
    }

    return 0;
  }

  /// Add coin earning to history
  static Future<void> _addCoinToHistory(int coinsEarned, int stepsAtTime) async {
    final prefs = await SharedPreferences.getInstance();

    List<Map<String, dynamic>> history = _decodeHistory(prefs.getString(coinHistoryKey));

    String today = DateTime.now().toString().split(" ")[0];
    int timestamp = DateTime.now().millisecondsSinceEpoch;

    // Add single entry with coins earned
    history.add({
      'date': today,
      'stepsAtTime': stepsAtTime,
      'coinsEarned': coinsEarned,
      'timestamp': timestamp,
    });

    // Keep only last 50 entries
    if (history.length > 50) {
      history = history.sublist(history.length - 50);
    }

    await prefs.setString(coinHistoryKey, _encodeHistory(history));
  }

  /// Decode history from JSON
  static List<Map<String, dynamic>> _decodeHistory(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Encode history to JSON
  static String _encodeHistory(List<Map<String, dynamic>> history) {
    return jsonEncode(history);
  }

  /// Get current coin balance
  static Future<int> getCoins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(coinsKey) ?? 0;
  }

  /// Add coins manually
  static Future<void> addCoins(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(coinsKey) ?? 0;
    await prefs.setInt(coinsKey, current + amount);
  }

  /// Spend coins
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

  /// Reset all coins
  static Future<void> resetCoins() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(coinsKey);
    await prefs.remove(totalStepsEarnedKey);
    await prefs.remove(lastCoinMilestoneKey);
    await prefs.remove(coinHistoryKey);

    // 🆕 Reset daily limit too
    await prefs.remove(dailyCoinsEarnedKey);
    await prefs.remove(dailyCoinsDateKey);

    // Reset cache
    _cachedLastMilestone = -1;
    _lastProcessedSteps = -1;
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
      'lastMilestone': prefs.getInt(lastCoinMilestoneKey) ?? 0,
      'lastDate': prefs.getString(lastDateKey),
      // 🆕 Include daily info
      'dailyEarned': prefs.getInt(dailyCoinsEarnedKey) ?? 0,
      'dailyLimit': maxDailyCoins,
    };
  }

  /// Clear all data
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _cachedLastMilestone = -1;
    _lastProcessedSteps = -1;
  }

  // Add these methods inside your StepStorage class

  static Future<void> addAdReward(int coins) async {
    final prefs = await SharedPreferences.getInstance();

    // Update total ad coins
    int currentTotal = prefs.getInt('total_ad_coins') ?? 0;
    await prefs.setInt('total_ad_coins', currentTotal + coins);

    // Add to ad history
    final historyJson = prefs.getString('ad_history') ?? '[]';
    final List<dynamic> history = jsonDecode(historyJson);

    history.add({
      'date': DateTime.now().toIso8601String().split('T')[0],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'coinsEarned': coins,
      'source': 'ad',
    });

    await prefs.setString('ad_history', jsonEncode(history));
  }

  static Future<Map<String, dynamic>> getAdCoinsData() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('ad_history') ?? '[]';

    return {
      'totalAdCoins': prefs.getInt('total_ad_coins') ?? 0,
      'adHistory': jsonDecode(historyJson),
    };
  }

  /// Debug print all data
  static Future<void> debugPrint() async {
    final prefs = await SharedPreferences.getInstance();
    print("=== STORAGE DEBUG ===");
    print("coins: ${prefs.getInt(coinsKey)}");
    print("lastMilestone: ${prefs.getInt(lastCoinMilestoneKey)}");
    print("totalStepsEarned: ${prefs.getInt(totalStepsEarnedKey)}");
    print("cachedMilestone: $_cachedLastMilestone");
    print("lastProcessed: $_lastProcessedSteps");
    print("dailyEarned: ${prefs.getInt(dailyCoinsEarnedKey)}");
    print("dailyLimit: $maxDailyCoins");
    print("====================");
  }
}