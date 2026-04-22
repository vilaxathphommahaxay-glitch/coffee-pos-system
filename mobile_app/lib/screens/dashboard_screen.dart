import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../services/offline_db.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final NumberFormat fmt = NumberFormat("#,##0");

  double totalRevenue = 0;
  int totalOrders = 0;
  double avgTicket = 0;
  int activeHold = 0; // This could come from a different source if needed
  List<Map<String, dynamic>> topProducts = [];
  List<double> hourlySales = List.filled(8, 0.0); // 8am - 3pm

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    _fetchLocalStats();
  }

  Future<void> _fetchLocalStats() async {
    setState(() => isLoading = true);
    
    try {
      final dbHelper = OfflineDBHelper.instance;
      final List<Map<String, dynamic>> rows = await dbHelper.getUnsyncedOrders();
      
      double revenue = 0;
      int ordersCount = 0;
      Map<String, int> productCounts = {};
      List<double> hourlyData = List.filled(8, 0.0);
      
      final today = DateTime.now().toIso8601String().split('T')[0];

      for (var row in rows) {
        final createdAt = row['created_at'] as String;
        if (!createdAt.startsWith(today)) continue;

        final payload = json.decode(row['payload'] as String);
        final amount = (payload['total_amount'] as num).toDouble();
        
        revenue += amount;
        ordersCount++;

        // Calculate Hourly (Simple 8am-3pm mapping)
        final time = DateTime.parse(createdAt);
        int hourIdx = time.hour - 8;
        if (hourIdx >= 0 && hourIdx < 8) {
          hourlyData[hourIdx] += amount;
        }

        // Top Products
        final items = payload['items'] as List;
        for (var item in items) {
          final name = item['product_name'] as String;
          final qty = item['quantity'] as int;
          productCounts[name] = (productCounts[name] ?? 0) + qty;
        }
      }

      // Process Top Products for UI
      var sortedProducts = productCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      int totalQty = productCounts.values.fold(0, (sum, q) => sum + q);
      
      List<Map<String, dynamic>> processedProducts = [];
      final colors = [Colors.amber, Colors.orange, Colors.green, Colors.blue, Colors.purple];
      
      for (int i = 0; i < sortedProducts.length && i < 5; i++) {
        processedProducts.add({
          "name": sortedProducts[i].key,
          "percentage": totalQty > 0 ? (sortedProducts[i].value / totalQty * 100).round() : 0,
          "color": colors[i % colors.length],
        });
      }

      // Normalize Hourly Data for Chart (0.0 to 1.0)
      double maxHour = hourlyData.reduce((a, b) => a > b ? a : b);
      List<double> normalizedHourly = hourlyData.map((v) => maxHour > 0 ? v / maxHour : 0.0).toList();

      if (mounted) {
        setState(() {
          totalRevenue = revenue;
          totalOrders = ordersCount;
          avgTicket = ordersCount > 0 ? revenue / ordersCount : 0;
          topProducts = processedProducts;
          hourlySales = normalizedHourly;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _handleRefresh() {
    _animationController.reset();
    _animationController.forward();
    _fetchLocalStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text("OFFLINE ANALYTICS"),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _handleRefresh, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.picture_as_pdf_outlined)),
        ],
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchLocalStats,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("REAL-TIME LOCAL SALES", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                  const SizedBox(height: 15),
                  _buildKPIGrid(context),
                  
                  const SizedBox(height: 30),
                  
                  const Text("SALES TREND (HOURLY)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                  const SizedBox(height: 15),
                  _buildSalesTrendChart(context),

                  const SizedBox(height: 30),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("TOP SELLING ITEMS", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                            const SizedBox(height: 15),
                            _buildTopProductsList(context),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("PEAK HOURS", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                            const SizedBox(height: 15),
                            _buildBusyHoursBarChart(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildKPIGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.6,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      children: [
        _buildKPICard(context, "Revenue Today", fmt.format(totalRevenue), "LAK", Icons.payments, Colors.amber),
        _buildKPICard(context, "Total Orders", totalOrders.toString(), "Tickets", Icons.shopping_bag, Colors.blueAccent),
        _buildKPICard(context, "Avg Ticket", fmt.format(avgTicket), "LAK", Icons.receipt, Colors.greenAccent),
        _buildKPICard(context, "Unsynced", totalOrders.toString(), "Orders", Icons.cloud_off, Colors.orangeAccent),
      ],
    );
  }

  Widget _buildKPICard(BuildContext context, String title, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Text(unit, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTrendChart(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 250,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return CustomPaint(
            painter: LineChartPainter(
              points: hourlySales,
              color: colorScheme.primary,
              progress: _animationController.value,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopProductsList(BuildContext context) {
    if (topProducts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: Text("No Sales Data", style: TextStyle(color: Colors.grey))),
      );
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: topProducts.map((p) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("${p['percentage']}%", style: TextStyle(color: p['color'], fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: p['percentage'] / 100,
                backgroundColor: Colors.grey[800],
                color: p['color'],
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildBusyHoursBarChart(BuildContext context) {
    final List<String> times = ["8a", "9a", "10a", "11a", "12p", "1p", "2p", "3p"];
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 250,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(hourlySales.length, (index) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Container(
                    width: 15,
                    height: 180 * hourlySales[index] * _animationController.value,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(times[index], style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          );
        }),
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<double> points;
  final Color color;
  final double progress;

  LineChartPainter({required this.points, required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final xStep = size.width / (points.length - 1);
    
    path.moveTo(0, size.height * (1 - points[0]));
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, size.height * (1 - points[0]));

    for (int i = 1; i < points.length; i++) {
      final x = i * xStep * progress;
      final y = size.height * (1 - points[i]);
      path.lineTo(x, y);
      fillPath.lineTo(x, y);
    }

    fillPath.lineTo(size.width * progress, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw points
    final dotPaint = Paint()..color = color;
    for (int i = 0; i < points.length; i++) {
      if (i * xStep <= size.width * progress) {
        canvas.drawCircle(Offset(i * xStep, size.height * (1 - points[i])), 4, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) => oldDelegate.progress != progress;
}

