import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../services/offline_db.dart';
import '../widgets/receipt_sheet.dart';

class KanbanBoardScreen extends StatefulWidget {
  const KanbanBoardScreen({super.key});

  @override
  State<KanbanBoardScreen> createState() => _KanbanBoardScreenState();
}

class _KanbanBoardScreenState extends State<KanbanBoardScreen> {
  List<Map<String, dynamic>> allActiveOrders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshOrders();
  }

  Future<void> _refreshOrders() async {
    final orders = await OfflineDBHelper.instance.getActiveOrders();
    if (mounted) {
      setState(() {
        allActiveOrders = orders;
        isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    await OfflineDBHelper.instance.updateOrderStatus(id, newStatus);
    _refreshOrders();
  }

  Future<void> _archive(String id) async {
    await OfflineDBHelper.instance.archiveOrder(id);
    _refreshOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("LIVE ORDER QUEUE"),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _refreshOrders, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(child: _buildColumn("To Do", "todo", Colors.redAccent.withOpacity(0.05))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildColumn("Brewing", "brewing", Colors.orangeAccent.withOpacity(0.05))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildColumn("Done", "done", Colors.green.withOpacity(0.05))),
                ],
              ),
            ),
    );
  }

  Widget _buildColumn(String title, String status, Color bgColor) {
    final columnOrders = allActiveOrders.where((o) => o['status'] == status).toList();

    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        _updateStatus(details.data, status);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: candidateData.isNotEmpty ? Theme.of(context).colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                ),
                child: Text(
                  "$title (${columnOrders.length})",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: columnOrders.length,
                  itemBuilder: (context, index) {
                    final orderRow = columnOrders[index];
                    final String orderId = orderRow['id'];
                    final payload = json.decode(orderRow['payload']);
                    
                    return Draggable<String>(
                      data: orderId,
                      feedback: Material(
                        color: Colors.transparent,
                        child: SizedBox(
                          width: 200,
                          child: _buildOrderCard(orderId, payload, status, isDragging: true),
                        ),
                      ),
                      childWhenDragging: Opacity(opacity: 0.3, child: _buildOrderCard(orderId, payload, status)),
                      child: _buildOrderCard(orderId, payload, status),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(String id, Map<String, dynamic> payload, String status, {bool isDragging = false}) {
    final List items = payload['items'];
    final String time = DateFormat("HH:mm").format(DateTime.parse(payload['created_at'] ?? DateTime.now().toIso8601String()));
    final shortId = id.split('_').last;

    return Card(
      elevation: isDragging ? 8 : 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("#$shortId", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const Divider(height: 15),
            ...items.map((i) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                "${i['quantity']}x ${i['product_name']}",
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            )).toList(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => showDigitalReceipt(context, payload),
                  child: const Icon(Icons.info_outline, size: 18, color: Colors.blueGrey),
                ),
                if (status == 'done')
                  InkWell(
                    onTap: () => _archive(id),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green),
                        SizedBox(width: 4),
                        Text("Archive", style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
