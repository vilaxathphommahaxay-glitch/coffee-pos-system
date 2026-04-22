import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class BaristaScreen extends StatefulWidget {
  const BaristaScreen({super.key});

  @override
  State<BaristaScreen> createState() => _BaristaScreenState();
}

class _BaristaScreenState extends State<BaristaScreen> {
  final String serverUrl = "http://192.168.1.50:8000";
  List<dynamic> pendingOrders = [];
  bool isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    fetchOrders();
    // Auto refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => fetchOrders());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchOrders() async {
    try {
      final response = await http.get(Uri.parse('$serverUrl/orders')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          // In a real app, we would filter by status='pending'
          // For now, we show the latest orders
          pendingOrders = data;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("BDS Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _markAsCompleted(int index) {
    setState(() {
      pendingOrders.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Order marked as Completed! ✅"), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Barista Queue (BDS)"),
        actions: [
          IconButton(onPressed: fetchOrders, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pendingOrders.isEmpty
              ? const Center(child: Text("No pending orders. Take a break! ☕"))
              : GridView.builder(
                  padding: const EdgeInsets.all(15),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: pendingOrders.length,
                  itemBuilder: (context, index) {
                    final order = pendingOrders[index];
                    final items = order['items'] as List<dynamic>;
                    final time = DateTime.parse(order['created_at']);

                    return Dismissible(
                      key: Key(order['id'].toString()),
                      onDismissed: (_) => _markAsCompleted(index),
                      background: Container(
                        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(15)),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.check_circle, color: Colors.white, size: 40),
                      ),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Order #${order['id']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(DateFormat('HH:mm').format(time), style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                              const Divider(),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: items.length,
                                  itemBuilder: (context, idx) {
                                    final item = items[idx];
                                    return Text(
                                      "• ${item['quantity']}x ${item['product_name'] ?? 'Item'} (${item['item_type']})",
                                      style: const TextStyle(fontSize: 14),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text("Swipe right to complete →", style: TextStyle(fontSize: 10, color: Colors.orange)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
