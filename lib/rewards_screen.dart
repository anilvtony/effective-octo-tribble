import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'step_storage.dart';
import 'dart:math' show pi;

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  int coinBalance = 0;
  List<Map<String, dynamic>> recentSpending = [];

  final List<Map<String, dynamic>> giftCards = [
    {
      'name': 'Amazon Gift Card',
      'value': '₹1,000',
      'coins': 10000,
      'color': [Colors.orange.shade400, Colors.orange.shade700],
      'icon': Icons.card_giftcard,
    },
    {
      'name': 'Flipkart Gift Card',
      'value': '₹500',
      'coins': 5000,
      'color': [Colors.blue.shade400, Colors.blue.shade700],
      'icon': Icons.shopping_bag,
    },
    {
      'name': 'Google Play',
      'value': '₹100',
      'coins': 1000,
      'color': [Colors.green.shade400, Colors.green.shade700],
      'icon': Icons.play_circle_fill,
    },
    {
      'name': 'Starbucks',
      'value': '₹50',
      'coins': 500,
      'color': [Colors.green.shade600, Colors.green.shade900],
      'icon': Icons.coffee,
    },
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    int coins = await StepStorage.getCoins();
    List<Map<String, dynamic>> spending = await getRecentSpending();

    setState(() {
      coinBalance = coins;
      recentSpending = spending;
    });
  }

  Future<List<Map<String, dynamic>>> getRecentSpending() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonStr = prefs.getString('spending_history');

    if (jsonStr == null || jsonStr.isEmpty) return [];

    try {
      List<dynamic> decoded = jsonDecode(jsonStr);
      List<Map<String, dynamic>> allSpending = decoded.cast<Map<String, dynamic>>();

      allSpending.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));

      return allSpending.take(10).toList();
    } catch (e) {
      return [];
    }
  }

  // 🎨 Beautiful popup for insufficient coins - CHANGED TO COMFORT COLORS (Indigo/Blue)
  void showInsufficientCoinsDialog(Map<String, dynamic> giftCard) {
    int requiredCoins = giftCard['coins'] as int;
    int neededCoins = requiredCoins - coinBalance;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                // CHANGED: Red → Indigo/Blue for comfort
                colors: [
                  Color(0xFF5C6BC0),
                  Color(0xFF3949AB),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5C6BC0).withOpacity(0.4),
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
                        child: const Icon(
                          Icons.lock_outline,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Insufficient Coins!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    children: [
                      Text(
                        "${giftCard['name']}",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.monetization_on,
                                  color: Colors.amber,
                                  size: 28,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "$requiredCoins",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "coins required",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Text(
                                  "You Have",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.monetization_on,
                                      color: Colors.amber.shade300,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "$coinBalance",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              height: 30,
                              width: 1,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            Column(
                              children: [
                                Text(
                                  "Need More",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.monetization_on,
                                      color: Colors.amber.shade300,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "$neededCoins",
                                      style: const TextStyle(
                                        color: Colors.amber,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "Walk more or watch ads to earn coins! 🚶📺",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

                /*const SizedBox(height: 16),

                // Watch Ad Button in popup - CHANGED TO TEAL/CYAN
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        // CHANGED: Pink/Red → Teal/Cyan
                        colors: [Color(0xFF26C6DA), Color(0xFF00BCD4)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        showWatchAdDialog(context);
                      },
                      icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                      label: const Text(
                        "WATCH AD +50",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),*/

                const SizedBox(height: 12),

                // OK Button - CHANGED TO INDIGO
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        // CHANGED: Red → Indigo for button text
                        foregroundColor: const Color(0xFF3949AB),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        "OK, Got It!",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🎬 Show Watch Ad Dialog - CHANGED TO COMFORT COLORS (Teal/Cyan)
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
                // CHANGED: Pink/Red → Teal/Cyan
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
                                  "+50",
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
                      const SizedBox(height: 5),
                      Text(
                        "⚡ No daily limit on ad rewards",
                        style: TextStyle(color: Colors.amber.shade300, fontSize: 12, fontStyle: FontStyle.italic),
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
                            // CHANGED: Red → Teal
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

  // 🎬 Watch ad and give reward
  Future<void> watchAdAndReward() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    await Future.delayed(const Duration(seconds: 2));

    Navigator.pop(context);

    await StepStorage.addCoins(50);
    await loadData();

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
              "+50 Coins Added!",
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

  Future<void> buyGiftCard(Map<String, dynamic> giftCard) async {
    int cost = giftCard['coins'] as int;

    if (coinBalance < cost) {
      showInsufficientCoinsDialog(giftCard);
      return;
    }

    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Purchase'),
        content: Text(
          'Buy ${giftCard['name']} worth ${giftCard['value']}?\n\n'
              'This will cost $cost coins.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Buy', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    bool success = await StepStorage.spendCoins(cost);

    if (success) {
      await addSpendingEntry(giftCard['name'], cost, giftCard['value']);
      await loadData();

      // 🎉 Show confetti celebration
      showConfettiCelebration(context, giftCard['name'] as String, giftCard['value'] as String);
    }
  }

  // 🎉 Confetti celebration dialog
  void showConfettiCelebration(BuildContext context, String itemName, String value) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                colors: [Color(0xFFFF6B6B), Color(0xFF4ECDC4), Color(0xFFFFE66D), Color(0xFF95E1D3)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated confetti area
                Container(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      // 🎊 Celebration emojis animation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _bounceEmoji('🎉', 0),
                          _bounceEmoji('🎊', 100),
                          _bounceEmoji('✨', 200),
                          _bounceEmoji('🎁', 300),
                          _bounceEmoji('🎈', 400),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Gift icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.card_giftcard,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Success text
                      const Text(
                        "Congratulations!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Item name
                      Text(
                        "You got $itemName",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5),

                      // Value
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Worth $value",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Coins spent info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.amber, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        "Coins well spent!",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

                // Continue button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4ECDC4),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                      ),
                      child: const Text(
                        "AWESOME! 🎉",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// Helper for bouncing emoji animation
  Widget _bounceEmoji(String emoji, int delay) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, -20 * value),
          child: Transform.scale(
            scale: 0.5 + (0.5 * value),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 32),
            ),
          ),
        );
      },
    );
  }

  Future<void> addSpendingEntry(String itemName, int coinsSpent, String value) async {
    final prefs = await SharedPreferences.getInstance();

    List<Map<String, dynamic>> history = [];
    String? existing = prefs.getString('spending_history');

    if (existing != null && existing.isNotEmpty) {
      try {
        history = (jsonDecode(existing) as List).cast<Map<String, dynamic>>();
      } catch (e) {
        history = [];
      }
    }

    String today = DateTime.now().toString().split(" ")[0];
    int timestamp = DateTime.now().millisecondsSinceEpoch;

    history.add({
      'date': today,
      'timestamp': timestamp,
      'itemName': itemName,
      'coinsSpent': coinsSpent,
      'value': value,
    });

    await prefs.setString('spending_history', jsonEncode(history));
  }

  void navigateToFullHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FullSpendingHistoryScreen(),
      ),
    );
  }

  String formatDateTime(int timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    String time = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    String dateStr = "${date.day}/${date.month}/${date.year}";
    return "$dateStr at $time";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),

      appBar: AppBar(
        title: const Text("Rewards"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: RefreshIndicator(
        onRefresh: loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wallet Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.amber, Colors.orange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 28,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Wallet Balance",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          color: Colors.white,
                          size: 36,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "$coinBalance",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "coins available",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

             /* const SizedBox(height: 20),

              // 🎬 WATCH ADS BUTTON - CHANGED TO TEAL/CYAN
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    // CHANGED: Pink/Red → Teal/Cyan
                    colors: [Color(0xFF26C6DA), Color(0xFF00BCD4)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF26C6DA).withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => showWatchAdDialog(context),
                    borderRadius: BorderRadius.circular(16),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_circle_fill, color: Colors.white, size: 32),
                        SizedBox(width: 12),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "WATCH AD",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              "+50 COINS INSTANTLY",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 12),
                        Icon(Icons.monetization_on, color: Colors.amber, size: 28),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Center(
                child: Text(
                  "💡 Watch ads anytime to earn bonus coins (No daily limit)",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ),*/

              const SizedBox(height: 30),

              // Gift Cards Section
              const Text(
                "Gift Cards",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "Redeem your coins for exciting rewards",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),

              // Gift Cards Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemCount: giftCards.length,
                itemBuilder: (context, index) {
                  final card = giftCards[index];
                  final bool canAfford = coinBalance >= (card['coins'] as int);

                  return GestureDetector(
                    onTap: () => buyGiftCard(card),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: canAfford
                              ? (card['color'] as List<Color>)
                              : [Colors.grey.shade400, Colors.grey.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (canAfford ? card['color'][0] : Colors.grey)
                                .withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  card['icon'] as IconData,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                const Spacer(),
                                Text(
                                  card['name'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  card['value'] as String,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.monetization_on,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${card['coins']}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!canAfford)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.lock,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              // Spending History Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recent Spending",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: navigateToFullHistory,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: const Text("Select Dates"),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Recent Spending List (Last 10 entries)
              if (recentSpending.isEmpty)
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 50,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "No spending yet",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Buy gift cards to see history here",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentSpending.length,
                  itemBuilder: (context, index) {
                    final entry = recentSpending[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              // CHANGED: Red → Indigo for spending icon background
                              color: const Color(0xFF5C6BC0).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.shopping_cart,
                              // CHANGED: Red → Indigo for icon
                              color: Color(0xFF5C6BC0),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry['itemName'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatDateTime(entry['timestamp'] ?? 0),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.monetization_on,
                                    // CHANGED: Red → Indigo for coin icon
                                    color: Color(0xFF5C6BC0),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    "-${entry['coinsSpent']}",
                                    style: const TextStyle(
                                      // CHANGED: Red → Indigo for amount
                                      color: Color(0xFF5C6BC0),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry['value'] ?? '',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Full Spending History Screen with Date Filter
class FullSpendingHistoryScreen extends StatefulWidget {
  const FullSpendingHistoryScreen({super.key});

  @override
  State<FullSpendingHistoryScreen> createState() => _FullSpendingHistoryScreenState();
}

class _FullSpendingHistoryScreenState extends State<FullSpendingHistoryScreen> {
  List<Map<String, dynamic>> allSpending = [];
  List<Map<String, dynamic>> filteredSpending = [];
  DateTime? startDate;
  DateTime? endDate;
  int totalSpent = 0;

  @override
  void initState() {
    super.initState();
    endDate = DateTime.now();
    startDate = endDate!.subtract(const Duration(days: 30));
    loadSpendingHistory();
  }

  Future<void> loadSpendingHistory() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonStr = prefs.getString('spending_history');

    List<Map<String, dynamic>> history = [];
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        history = (jsonDecode(jsonStr) as List).cast<Map<String, dynamic>>();
      } catch (e) {
        history = [];
      }
    }

    history.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));

    setState(() {
      allSpending = history;
      applyDateFilter();
    });
  }

  void applyDateFilter() {
    if (startDate == null || endDate == null) {
      filteredSpending = allSpending;
    } else {
      filteredSpending = allSpending.where((entry) {
        String entryDate = entry['date'] ?? '';
        DateTime entryDateTime = DateTime.tryParse(entryDate) ?? DateTime(2000);

        DateTime start = DateTime(startDate!.year, startDate!.month, startDate!.day);
        DateTime end = DateTime(endDate!.year, endDate!.month, endDate!.day);
        DateTime entryNormalized = DateTime(entryDateTime.year, entryDateTime.month, entryDateTime.day);

        return !entryNormalized.isBefore(start) && !entryNormalized.isAfter(end);
      }).toList();
    }

    totalSpent = filteredSpending.fold<int>(0, (sum, entry) => sum + ((entry['coinsSpent'] ?? 0) as int));
  }

  Future<void> selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
        applyDateFilter();
      });
    }
  }

  String formatDate(DateTime d) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "${months[d.month - 1]} ${d.day}, ${d.year}";
  }

  String formatDateTime(int timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    String time = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    String dateStr = "${date.day}/${date.month}/${date.year}";
    return "$dateStr at $time";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),

      appBar: AppBar(
        title: const Text("Spending History"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: selectDateRange,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_today, size: 18, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                startDate == null
                                    ? "Select Dates"
                                    : "${formatDate(startDate!)} - ${formatDate(endDate!)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        "Total Spent",
                        "$totalSpent",
                        Icons.monetization_on,
                        // CHANGED: Red → Indigo
                        const Color(0xFF5C6BC0),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCard(
                        "Transactions",
                        "${filteredSpending.length}",
                        Icons.receipt,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: filteredSpending.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No transactions found",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Try selecting a different date range",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredSpending.length,
              itemBuilder: (context, index) {
                final entry = filteredSpending[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            // CHANGED: Red → Indigo
                            colors: [Color(0xFF7986CB), Color(0xFF5C6BC0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.shopping_bag,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry['itemName'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  formatDateTime(entry['timestamp'] ?? 0),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              // CHANGED: Red → Indigo
                              color: const Color(0xFF5C6BC0).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.monetization_on,
                                  // CHANGED: Red → Indigo
                                  color: Color(0xFF5C6BC0),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "-${entry['coinsSpent']}",
                                  style: const TextStyle(
                                    // CHANGED: Red → Indigo
                                    color: Color(0xFF5C6BC0),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            entry['value'] ?? '',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}