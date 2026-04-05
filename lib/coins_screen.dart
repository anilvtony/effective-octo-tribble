import 'package:flutter/material.dart';
import 'step_storage.dart';

class CoinsScreen extends StatefulWidget {
  const CoinsScreen({super.key});

  @override
  State<CoinsScreen> createState() => _CoinsScreenState();
}

class _CoinsScreenState extends State<CoinsScreen> {
  int coins = 0;
  int totalCoinsEarned = 0;
  List<Map<String, dynamic>> coinHistory = [];

  DateTime? fromDate;
  DateTime? toDate;

  @override
  void initState() {
    super.initState();
    loadCoinsData();
  }

  Future<void> loadCoinsData() async {
    final data = await StepStorage.getCoinsData();

    // CRITICAL FIX: Use the actual stored coin balance as the source of truth
    // Available coins should equal total earned on day 1 (before spending)
    int availableCoins = data['coins'] ?? 0;

    // Calculate total earned from history properly
    int calculatedEarned = _calculateTotalFromHistory(data['history']);

    // If no history but has coins, or first day, make them equal
    if (calculatedEarned == 0 && availableCoins > 0) {
      calculatedEarned = availableCoins;
    }

    setState(() {
      coins = availableCoins;
      totalCoinsEarned = calculatedEarned;
      coinHistory = List<Map<String, dynamic>>.from(data['history'] ?? []);
    });
  }

  /// FIXED: Properly calculate total from history
  int _calculateTotalFromHistory(List<dynamic>? history) {
    if (history == null || history.isEmpty) return 0;

    int total = 0;
    for (var item in history) {
      if (item is Map) {
        // Get coinsEarned field, default to 1 for backward compatibility
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
            Container(
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
            ),

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
                const SizedBox(width: 15),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.monetization_on,
                    title: "Total Earned",
                    value: totalCoinsEarned.toString(),
                    color: Colors.green,
                    subtitle: "Lifetime",
                  ),
                ),
              ],
            ),

            // Show spent coins only if there's a difference
            if (totalCoinsEarned > coins)
              Container(
                margin: const EdgeInsets.only(top: 15),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart, color: Colors.red.shade400, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "${totalCoinsEarned - coins} coins spent",
                      style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

            // DEBUG: Show if they're equal (first day)
            if (coins == totalCoinsEarned && coins > 0)
              Container(
                margin: const EdgeInsets.only(top: 15),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade400, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "All coins available! Nothing spent yet.",
                      style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600),
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
      dailyTotals[date] = dailyTotals[date]! + (item['coinsEarned'] ?? 1) as int;
    }

    rangeTotal = dailyTotals.values.fold(0, (sum, val) => sum + val);
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
          /// SUMMARY CARD
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

          /// DAY-WISE LIST
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