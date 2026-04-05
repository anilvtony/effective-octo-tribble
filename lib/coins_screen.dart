import 'package:flutter/material.dart';
import 'step_storage.dart';

class CoinsScreen extends StatefulWidget {
  const CoinsScreen({super.key});

  @override
  State<CoinsScreen> createState() => _CoinsScreenState();
}

class _CoinsScreenState extends State<CoinsScreen> {
  int coins = 0;
  int totalStepsEarned = 0;
  List<Map<String, dynamic>> coinHistory = [];

  @override
  void initState() {
    super.initState();
    loadCoinsData();
  }

  /// Load coins and history from storage
  Future<void> loadCoinsData() async {
    final data = await StepStorage.getCoinsData();

    setState(() {
      coins = data['coins'] ?? 0;
      totalStepsEarned = data['totalStepsEarned'] ?? 0;
      coinHistory = List<Map<String, dynamic>>.from(data['history'] ?? []);
    });
  }

  /// Refresh data when screen becomes active
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadCoinsData();
  }

  String formatDate(String dateStr) {
    DateTime date = DateTime.parse(dateStr);
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    // Calculate progress to next coin (every 1000 steps)
    int stepsProgress = totalStepsEarned % 1000;
    double progressPercent = stepsProgress / 1000;

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
                  const Icon(
                    Icons.monetization_on,
                    size: 60,
                    color: Colors.white,
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    "Total Coins",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    "$coins",
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Progress to next coin
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),

                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "$stepsProgress / 1000 steps",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "${(progressPercent * 100).toInt()}%",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progressPercent,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                            minHeight: 10,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          "Walk 1000 more steps to earn 1 coin!",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
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
                    icon: Icons.directions_walk,
                    title: "Steps Earned",
                    value: totalStepsEarned.toString(),
                    color: Colors.blue,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: _buildStatCard(
                    icon: Icons.history,
                    title: "Total Earned",
                    value: coinHistory.length.toString(),
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            /// COIN HISTORY
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Earning History",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (coinHistory.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      await StepStorage.clearCoinHistory();
                      loadCoinsData();
                    },
                    child: const Text("Clear"),
                  ),
              ],
            ),

            const SizedBox(height: 15),

            coinHistory.isEmpty
                ? Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 50,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 15),
                  Text(
                    "No coins earned yet!\nStart walking to earn coins.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: coinHistory.length > 10 ? 10 : coinHistory.length,
              itemBuilder: (context, index) {
                // Show most recent first
                final item = coinHistory[coinHistory.length - 1 - index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
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
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add_circle,
                          color: Colors.amber,
                          size: 24,
                        ),
                      ),

                      const SizedBox(width: 15),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "+1 Coin Earned",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Steps: ${item['stepsAtTime']}",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Text(
                        formatDate(item['date']),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
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
  }) {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
          ),
        ],
      ),

      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}