import 'package:flutter/material.dart';
import 'step_storage.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class CoinsScreen extends StatefulWidget {
  const CoinsScreen({super.key});

  @override
  State<CoinsScreen> createState() => _CoinsScreenState();
}

class _CoinsScreenState extends State<CoinsScreen> {
  int coins = 0;
  int walkCoinsEarned = 0;
  int adCoinsEarned = 0;
  int get totalCoinsEarned => walkCoinsEarned + adCoinsEarned;
  // Ad cooldown tracking
  int adsWatchedToday = 0;
  DateTime? lastAdWatchedTime;
  Timer? _cooldownTimer;
  String cooldownText = "";
  bool isAdButtonEnabled = true;

  List<Map<String, dynamic>> coinHistory = [];
  List<Map<String, dynamic>> adHistory = [];
  Map<String, dynamic> dailyInfo = {};

  DateTime? fromDate;
  DateTime? toDate;

  @override
  void initState() {
    super.initState();
    loadCoinsData();
    checkAndResetDailyAdCount();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }


  // 🕐 Check if it's a new day and reset ad count
  Future<void> checkAndResetDailyAdCount() async {
    final prefs = await SharedPreferences.getInstance();
    String? lastDateStr = prefs.getString('last_ad_date');
    String todayStr = DateTime.now().toIso8601String().split('T')[0];

    if (lastDateStr != todayStr) {
      // New day - reset everything
      await prefs.setInt('ads_watched_today', 0);
      await prefs.setString('last_ad_date', todayStr);
      await prefs.remove('last_ad_watched_time');
      adsWatchedToday = 0;
      lastAdWatchedTime = null;
    } else {
      // Same day - load existing data
      adsWatchedToday = prefs.getInt('ads_watched_today') ?? 0;
      int? lastTimeMillis = prefs.getInt('last_ad_watched_time');
      if (lastTimeMillis != null) {
        lastAdWatchedTime = DateTime.fromMillisecondsSinceEpoch(lastTimeMillis);
      }
    }

    updateCooldownStatus();
  }

  // ⏱️ Calculate required cooldown based on ads watched
  int getRequiredCooldownSeconds() {
    if (adsWatchedToday < 3) {
      return 30; // First 3 ads: 30-60 sec gap (using 30)
    } else if (adsWatchedToday < 6) {
      return 120; // Next 3 ads (4-6): 2 min gap
    } else {
      return 300; // After 6 ads: 5 min gap
    }
  }

  // 🔄 Update button state and cooldown text
  void updateCooldownStatus() {
    if (lastAdWatchedTime == null) {
      setState(() {
        isAdButtonEnabled = true;
        cooldownText = "";
      });
      return;
    }

    int requiredSeconds = getRequiredCooldownSeconds();
    int elapsedSeconds = DateTime.now().difference(lastAdWatchedTime!).inSeconds;
    int remainingSeconds = requiredSeconds - elapsedSeconds;

    if (remainingSeconds <= 0) {
      setState(() {
        isAdButtonEnabled = true;
        cooldownText = "";
      });
    } else {
      setState(() {
        isAdButtonEnabled = false;
        cooldownText = formatCooldown(remainingSeconds);
      });

      // Start timer to update countdown
      _cooldownTimer?.cancel();
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        int newElapsed = DateTime.now().difference(lastAdWatchedTime!).inSeconds;
        int newRemaining = requiredSeconds - newElapsed;

        if (newRemaining <= 0) {
          timer.cancel();
          setState(() {
            isAdButtonEnabled = true;
            cooldownText = "";
          });
        } else {
          setState(() {
            cooldownText = formatCooldown(newRemaining);
          });
        }
      });
    }
  }

  // 📝 Format seconds to readable text
  String formatCooldown(int seconds) {
    if (seconds < 60) {
      return "$seconds sec";
    } else {
      int minutes = seconds ~/ 60;
      int secs = seconds % 60;
      return secs > 0 ? "$minutes:${secs.toString().padLeft(2, '0')}" : "$minutes min";
    }
  }

  // 💾 Save ad watch data
  Future<void> recordAdWatched() async {
    final prefs = await SharedPreferences.getInstance();
    adsWatchedToday++;
    lastAdWatchedTime = DateTime.now();

    await prefs.setInt('ads_watched_today', adsWatchedToday);
    await prefs.setInt('last_ad_watched_time', lastAdWatchedTime!.millisecondsSinceEpoch);
    await prefs.setString('last_ad_date', DateTime.now().toIso8601String().split('T')[0]);

    updateCooldownStatus();
  }





  Future<void> loadCoinsData() async {
    final data = await StepStorage.getCoinsData();
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      coins = data['coins'] ?? 0;
      walkCoinsEarned = _calculateTotalFromHistory(data['history']);
      adCoinsEarned = prefs.getInt('ad_coins_earned') ?? 0;
      coinHistory = List<Map<String, dynamic>>.from(data['history'] ?? []);
      dailyInfo = data['dailyInfo'] ?? {};
    });
  }

  int _calculateTotalFromHistory(List<dynamic>? history) {
    if (history == null || history.isEmpty) return 0;

    int total = 0;
    for (var item in history) {
      if (item is Map) {
        int earned = 1;
        if (item.containsKey('coinsEarned')) {
          var val = item['coinsEarned'];
          earned = (val is int) ? val : int.tryParse(val.toString()) ?? 1;
        }
        total += earned;
      }
    }
    return total;
  }

  Future<void> pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.amber,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DateRangeResultScreen(
            fromDate: picked.start,
            toDate: picked.end,
            coinHistory: coinHistory,
            totalLifetimeEarned: totalCoinsEarned,
          ),
        ),
      );
    }
  }

  /// 🎬 Show Watch Ad Dialog - CHANGED TO COMFORT COLORS (Teal/Cyan instead of Red)
  void showWatchAdDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                // CHANGED: Pink/Red → Teal/Cyan for comfort
                colors: [Color(0xFF26C6DA), Color(0xFF0097A7)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF26C6DA).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.videocam, color: Colors.white, size: 48),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Watch Video Ad",
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                        ),
                        child: const Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.monetization_on, color: Colors.amber, size: 36),
                                SizedBox(width: 10),
                                Text(
                                  "+10",
                                  style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              "COINS REWARD",
                              style: TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "Watch a short video ad to earn bonus coins instantly!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            watchAdAndReward();
                          },
                          icon: const Icon(Icons.play_arrow, size: 28),
                          label: const Text(
                            "WATCH AD NOW",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            // CHANGED: Red → Teal for button text color
                            foregroundColor: const Color(0xFF00838F),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Maybe Later",
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 🎬 Watch ad and give reward
  Future<void> watchAdAndReward() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    await Future.delayed(const Duration(seconds: 2));
    Navigator.pop(context);

    await StepStorage.addCoins(10);

    final prefs = await SharedPreferences.getInstance();
    int currentAdCoins = prefs.getInt('ad_coins_earned') ?? 0;
    await prefs.setInt('ad_coins_earned', currentAdCoins + 10);

    await recordAdWatched(); // ADD THIS LINE after setting coins

    await loadCoinsData();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 10),
            const Text("Reward Earned!"),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.monetization_on, size: 60, color: Colors.amber),
            SizedBox(height: 15),
            Text(
              "+10 Coins Added!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text("Thanks for watching. Enjoy your reward!"),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("Awesome!", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  String formatShortDate(DateTime date) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "${months[date.month - 1]} ${date.day}";
  }

  String formatDate(String dateStr) {
    DateTime date = DateTime.parse(dateStr);
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  String formatTime(int timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    String hour = date.hour.toString().padLeft(2, '0');
    String minute = date.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> recentHistory = coinHistory.length > 5
        ? coinHistory.sublist(coinHistory.length - 5)
        : coinHistory;

    int dailyEarned = dailyInfo['dailyEarned'] ?? 0;
    int maxDaily = dailyInfo['maxDaily'] ?? 500;
    int remaining = dailyInfo['remaining'] ?? 500;
    double progress = dailyEarned / maxDaily;
    bool limitReached = dailyEarned >= maxDaily;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),

      appBar: AppBar(
        title: const Text("My Coins"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            /// COIN BALANCE CARD
            /*Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.amber, Colors.orange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.monetization_on, size: 60, color: Colors.white),
                  const SizedBox(height: 15),
                  const Text(
                    "Available coins to spend",
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "$coins",
                    style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),*/

            const SizedBox(height: 30),

            /// STATS ROW
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.account_balance_wallet,
                    title: "Available",
                    value: coins.toString(),
                    color: Colors.blue,
                    subtitle: "To spend now",
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.directions_walk,
                    title: "Walk Coins",
                    value: walkCoinsEarned.toString(),
                    color: Colors.green,
                    subtitle: "From steps",
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.play_circle_fill,
                    title: "Ad Coins",
                    value: adCoinsEarned.toString(),
                    // CHANGED: Pink → Teal for ad coins card
                    color: const Color(0xFF00BCD4),
                    subtitle: "From videos",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.amber, Colors.orange],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monetization_on, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    "Total Earned: $totalCoinsEarned",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),




            const SizedBox(height: 20),

            /// 🎬 WATCH ADS BUTTON - CHANGED TO COMFORT COLORS (Teal/Cyan)
            /// 🎬 WATCH ADS BUTTON with COOLDOWN
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isAdButtonEnabled
                      ? [const Color(0xFF26C6DA), const Color(0xFF00BCD4)]
                      : [Colors.grey.shade400, Colors.grey.shade600],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isAdButtonEnabled
                        ? const Color(0xFF26C6DA).withOpacity(0.4)
                        : Colors.grey.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isAdButtonEnabled ? () => showWatchAdDialog(context) : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                          isAdButtonEnabled ? Icons.play_circle_fill : Icons.timer,
                          color: Colors.white,
                          size: 32
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAdButtonEnabled ? "WATCH AD" : "WAIT $cooldownText",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          if (isAdButtonEnabled)
                            Text(
                              "Ad ${adsWatchedToday + 1} today • +10 COINS",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.monetization_on, color: Colors.amber, size: 28),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            Center(
              child: Text(
                isAdButtonEnabled
                    ? "💡 ${adsWatchedToday < 3 ? 'First 3 ads: 30 sec gap' : adsWatchedToday < 6 ? 'Next 3 ads: 2 min gap' : 'After 6 ads: 5 min gap'} • Resets at 12 AM"
                    : "⏱️ Please wait before watching next ad",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// DAILY LIMIT PROGRESS CARD - CHANGED TO COMFORT COLORS (Indigo/Blue instead of Purple)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  // CHANGED: Purple → Indigo/Blue for comfort
                  colors: [Color(0xFF5C6BC0), Color(0xFF3949AB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5C6BC0).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.timer, color: Colors.white70),
                          SizedBox(width: 8),
                          Text(
                            "Daily Walk Limit",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: limitReached ? Colors.green : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          limitReached ? "COMPLETED!" : "$remaining LEFT",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "$dailyEarned",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        " / $maxDaily",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.monetization_on, color: Colors.amber, size: 32),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.amber, Colors.orange],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    limitReached
                        ? "🎉 You've earned all coins for today! Come back tomorrow."
                        : "Walk ${(remaining * 10)} more steps to earn $remaining more coins",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// EARNING HISTORY HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Earning History", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("Recent entries", style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),

                GestureDetector(
                  onTap: pickDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.withOpacity(0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.date_range, size: 16, color: Colors.amber),
                        SizedBox(width: 6),
                        Text("Select Dates", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            /// RECENT HISTORY
            recentHistory.isEmpty
                ? Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: const Column(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 50, color: Colors.grey),
                  SizedBox(height: 15),
                  Text("No coins earned yet!\nStart walking to earn coins.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            )
                : Column(
              children: recentHistory.reversed.map((item) {
                int coinsInEntry = item['coinsEarned'] ?? 1;
                int timestamp = item['timestamp'] ?? 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.add_circle, color: Colors.amber, size: 24),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("+$coinsInEntry Coin${coinsInEntry > 1 ? 's' : ''} Earned", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("Steps: ${item['stepsAtTime']}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(formatDate(item['date']), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          if (timestamp > 0)
                            Text(formatTime(timestamp), style: TextStyle(color: Colors.amber.shade700, fontSize: 11, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            if (coinHistory.length > 5)
              TextButton(
                onPressed: pickDateRange,
                child: const Text("View Full Report →", style: TextStyle(color: Colors.amber)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(color: Colors.grey.shade800, fontSize: 13, fontWeight: FontWeight.w600)),
          if (subtitle != null)
            Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ],
      ),
    );
  }
}

/// FULL SCREEN DATE RANGE RESULT SCREEN
class DateRangeResultScreen extends StatefulWidget {
  final DateTime fromDate;
  final DateTime toDate;
  final List<Map<String, dynamic>> coinHistory;
  final int totalLifetimeEarned;

  const DateRangeResultScreen({
    super.key,
    required this.fromDate,
    required this.toDate,
    required this.coinHistory,
    required this.totalLifetimeEarned,
  });

  @override
  State<DateRangeResultScreen> createState() => _DateRangeResultScreenState();
}

class _DateRangeResultScreenState extends State<DateRangeResultScreen> {
  Map<String, List<Map<String, dynamic>>> groupedByDate = {};
  Map<String, int> dailyTotals = {};
  int rangeTotal = 0;
  int totalDaysWithCoins = 0;

  @override
  void initState() {
    super.initState();
    processData();
  }

  void processData() {
    String fromStr = widget.fromDate.toString().split(" ")[0];
    String toStr = widget.toDate.toString().split(" ")[0];

    List<Map<String, dynamic>> filtered = widget.coinHistory.where((item) {
      String itemDate = item['date'];
      return itemDate.compareTo(fromStr) >= 0 && itemDate.compareTo(toStr) <= 0;
    }).toList();

    for (var item in filtered) {
      String date = item['date'];
      if (!groupedByDate.containsKey(date)) {
        groupedByDate[date] = [];
        dailyTotals[date] = 0;
      }
      groupedByDate[date]!.add(item);
      dailyTotals[date] = dailyTotals[date]! + ((item['coinsEarned'] ?? 1) as int);
    }

    rangeTotal = dailyTotals.values.fold<int>(0, (sum, val) => sum + val);
    totalDaysWithCoins = groupedByDate.length;

    groupedByDate = Map.fromEntries(
      groupedByDate.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
  }

  String formatDate(String dateStr) {
    DateTime date = DateTime.parse(dateStr);
    List<String> months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    List<String> days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    String dayName = days[date.weekday - 1];
    return "$dayName, ${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  String formatShortDateRange() {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    String from = "${months[widget.fromDate.month - 1]} ${widget.fromDate.day}";
    String to = "${months[widget.toDate.month - 1]} ${widget.toDate.day}, ${widget.toDate.year}";
    return "$from - $to";
  }

  String formatTime(int timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    String hour = date.hour.toString().padLeft(2, '0');
    String minute = date.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),

      appBar: AppBar(
        title: const Text("Earning Report"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.amber, Colors.orange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Column(
              children: [
                Text(formatShortDateRange(), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem("In This Range", rangeTotal.toString(), Icons.date_range),
                    _buildSummaryItem("Active Days", totalDaysWithCoins.toString(), Icons.calendar_today),
                    _buildSummaryItem("Lifetime Total", widget.totalLifetimeEarned.toString(), Icons.monetization_on),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: groupedByDate.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 20),
                  Text("No coins earned in this period", style: TextStyle(color: Colors.grey.shade600, fontSize: 18)),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: groupedByDate.length,
              itemBuilder: (context, index) {
                String date = groupedByDate.keys.elementAt(index);
                List<Map<String, dynamic>> entries = groupedByDate[date]!;
                int dayTotal = dailyTotals[date]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formatDate(date),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              "$dayTotal coin${dayTotal > 1 ? 's' : ''}",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                    ...entries.reversed.map((item) {
                      int coinsInEntry = item['coinsEarned'] ?? 1;
                      int timestamp = item['timestamp'] ?? 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8, left: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.add, color: Colors.amber, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("+$coinsInEntry coin${coinsInEntry > 1 ? 's' : ''}", style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text("At ${item['stepsAtTime']} steps", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                ],
                              ),
                            ),
                            if (timestamp > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                                child: Text(
                                  formatTime(timestamp),
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 10),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}