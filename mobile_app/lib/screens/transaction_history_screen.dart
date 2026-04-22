import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../services/offline_db.dart';
import '../widgets/receipt_sheet.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = true;
  final NumberFormat fmt = NumberFormat("#,##0");

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() => isLoading = true);
    try {
      final dbHelper = OfflineDBHelper.instance;
      final rows = await dbHelper.getUnsyncedOrders();
      
      List<Map<String, dynamic>> fetched = [];
      for (var row in rows) {
        final payload = json.decode(row['payload']);
        payload['local_id'] = row['id'];
        payload['created_at'] = row['created_at'];
        fetched.add(payload);
      }

      // Sort by newest first
      fetched.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));

      if (fetched.isEmpty) {
        fetched = _generateMockTransactions();
      }

      setState(() {
        transactions = fetched;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        transactions = _generateMockTransactions();
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _generateMockTransactions() {
    final now = DateTime.now();
    return [
      {
        "id": "MOCK_001",
        "created_at": now.subtract(const Duration(minutes: 5)).toIso8601String(),
        "total_amount": 45000.0,
        "payment_method": "CASH",
        "items": [
          {"product_name": "Dirty Coffee", "quantity": 1, "price_at_sale": 30000},
          {"product_name": "Espresso", "quantity": 1, "price_at_sale": 15000}
        ]
      },
      {
        "id": "MOCK_002",
        "created_at": now.subtract(const Duration(hours: 1)).toIso8601String(),
        "total_amount": 25000.0,
        "payment_method": "QR_SCAN",
        "items": [
          {"product_name": "Latte", "quantity": 1, "price_at_sale": 25000}
        ]
      },
      {
        "id": "MOCK_003",
        "created_at": now.subtract(const Duration(hours: 2)).toIso8601String(),
        "total_amount": 72000.0,
        "payment_method": "CASH",
        "items": [
          {"product_name": "V60 Ethiopia", "quantity": 1, "price_at_sale": 50000},
          {"product_name": "Croissant", "quantity": 1, "price_at_sale": 22000}
        ]
      },
      {
        "id": "MOCK_004",
        "created_at": now.subtract(const Duration(hours: 4)).toIso8601String(),
        "total_amount": 28000.0,
        "payment_method": "QR_SCAN",
        "items": [
          {"product_name": "Premium Matcha", "quantity": 1, "price_at_sale": 28000}
        ]
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("TRANSACTION HISTORY"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : transactions.isEmpty
              ? const Center(child: Text("No transactions yet"))
              : RefreshIndicator(
                  onRefresh: _fetchTransactions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      final date = DateFormat("HH:mm | dd MMM").format(DateTime.parse(tx['created_at']));
                      final id = tx['id']?.toString().split('_').last ?? "0000";
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          onTap: () => showDigitalReceipt(context, tx),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              tx['payment_method'] == "CASH" ? Icons.money : Icons.qr_code,
                              color: colorScheme.primary,
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("#$id", style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text("${fmt.format(tx['total_amount'])} LAK", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    tx['payment_method'],
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
