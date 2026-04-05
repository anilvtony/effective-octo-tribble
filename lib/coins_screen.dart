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

  // Date range filter
  DateTime? fromDate;
  DateTime? toDate;
  String filterLabel = "All Time";

  @override
  void initState() {
    super.initState();
    loadCoinsData();
  }

  Future<void> loadCoinsData() async {
    final data = await StepStorage.getCoinsData();

    int calculatedTotal = 0;
    List<Map<String, dynamic>> history = List<Map<String, dynamic>>.from(data['history'] ?? []);
    for (var item in history) {
      calculatedTotal += (item['coinsEarned'] ?? 1) as int;
    }

    setState(() {
      coins = data['coins'] ?? 0;
      totalCoinsEarned = calculatedTotal;
      coinHistory = history;
    });
  }

  /// Pick date range and show results in full screen
  Future<void> pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: fromDate != null && toDate != null
          ? DateTimeRange(start: fromDate!, end: toDate!)
          : null,
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
      setState(() {
        fromDate = picked.start;
        toDate = picked.end;
        filterLabel = "${formatShortDate(picked.start)} - ${formatShortDate(picked.end)}";
      });

      // Navigate to full screen results
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DateRangeResultScreen(
            fromDate: picked.start,
            toDate: picked.end,
            coinHistory: coinHistory,
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

  void clearFilter() {
    setState(() {
      fromDate = null;
      toDate = null;
      filterLabel = "All Time";
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show recent 5 entries on main screen with time
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
                  const Text("Total Coins", style: TextStyle(fontSize: 18, color: Colors.white70)),
                  const SizedBox(height: 5),
                  Text("$coins", style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// STATS ROW
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.monetization_on,
                    title: "Total Earned",
                    value: totalCoinsEarned.toString(),
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            /// EARNING HISTORY HEADER with DATE RANGE BUTTON
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Earning History", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(filterLabel, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  ],
                ),

                // DATE RANGE BUTTON
                GestureDetector(
                  onTap: pickDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.date_range, size: 16, color: Colors.amber),
                        const SizedBox(width: 6),
                        Text(
                          fromDate == null ? "Select Dates" : "View Report",
                          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            /// RECENT HISTORY (with time) - Main Screen
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
                            Text("+$coinsInEntry Coin${coinsInEntry > 1 ? 's' : ''} Earned",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("Steps: ${item['stepsAtTime']}",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(formatDate(item['date']),
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          if (timestamp > 0)
                            Text(formatTime(timestamp),
                                style: TextStyle(color: Colors.amber.shade700, fontSize: 11, fontWeight: FontWeight.w500)),
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
                child: const Text("View All History →", style: TextStyle(color: Colors.amber)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String title, required String value, required Color color}) {
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
          const SizedBox(height: 5),
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
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

  const DateRangeResultScreen({
    super.key,
    required this.fromDate,
    required this.toDate,
    required this.coinHistory,
  });

  @override
  State<DateRangeResultScreen> createState() => _DateRangeResultScreenState();
}

class _DateRangeResultScreenState extends State<DateRangeResultScreen> {
  Map<String, List<Map<String, dynamic>>> groupedByDate = {};
  Map<String, int> dailyTotals = {};
  int grandTotal = 0;
  int totalDaysWithCoins = 0;

  @override
  void initState() {
    super.initState();
    processData();
  }

  void processData() {
    String fromStr = widget.fromDate.toString().split(" ")[0];
    String toStr = widget.toDate.toString().split(" ")[0];

    // Filter history within date range
    List<Map<String, dynamic>> filtered = widget.coinHistory.where((item) {
      String itemDate = item['date'];
      return itemDate.compareTo(fromStr) >= 0 && itemDate.compareTo(toStr) <= 0;
    }).toList();

    // Group by date
    for (var item in filtered) {
      String date = item['date'];
      if (!groupedByDate.containsKey(date)) {
        groupedByDate[date] = [];
        dailyTotals[date] = 0;
      }
      groupedByDate[date]!.add(item);
      dailyTotals[date] = dailyTotals[date]! + (item['coinsEarned'] ?? 1) as int;
    }

    // Calculate totals
    grandTotal = dailyTotals.values.fold(0, (sum, val) => sum + val);
    totalDaysWithCoins = groupedByDate.length;

    // Sort dates descending
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
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem("Total Coins", grandTotal.toString(), Icons.monetization_on),
                    _buildSummaryItem("Active Days", totalDaysWithCoins.toString(), Icons.calendar_today),
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
                  Text("No coins earned in this period",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 18)),
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
                    // DATE HEADER with daily total
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
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "$dayTotal coin${dayTotal > 1 ? 's' : ''}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ENTRIES FOR THIS DAY (with time)
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
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add, color: Colors.amber, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("+$coinsInEntry coin${coinsInEntry > 1 ? 's' : ''}",
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text("At ${item['stepsAtTime']} steps",
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                ],
                              ),
                            ),
                            if (timestamp > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  formatTime(timestamp),
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
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
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}