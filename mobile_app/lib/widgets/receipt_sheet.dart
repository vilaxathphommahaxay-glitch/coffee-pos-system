import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void showDigitalReceipt(BuildContext context, Map<String, dynamic> orderData) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final items = orderData['items'] as List;
      final total = (orderData['total_amount'] as num).toDouble();
      final method = orderData['payment_method'] as String;
      
      // Use provided created_at if available, otherwise now
      String dateStr = orderData['created_at'] ?? DateTime.now().toIso8601String();
      final date = DateFormat("dd MMM yyyy, HH:mm").format(DateTime.parse(dateStr));

      return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5), // Ticket-like
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("ILA HOMEBAR", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'monospace')),
            const Text("Slow Bar Experience", style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'monospace')),
            const SizedBox(height: 10),
            const Text("--------------------------------", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("DATE:", style: TextStyle(color: Colors.black, fontSize: 12, fontFamily: 'monospace')), Text(date, style: const TextStyle(color: Colors.black, fontSize: 12, fontFamily: 'monospace'))]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("METHOD:", style: TextStyle(color: Colors.black, fontSize: 12, fontFamily: 'monospace')), Text(method, style: const TextStyle(color: Colors.black, fontSize: 12, fontFamily: 'monospace'))]),
            const SizedBox(height: 15),
            const Text("--------------------------------", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            ...items.map((i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text("${i['quantity']}x ${i['product_name']}", style: const TextStyle(color: Colors.black, fontSize: 14, fontFamily: 'monospace'))),
                  Text(NumberFormat("#,##0").format(i['price_at_sale'] * i['quantity']), style: const TextStyle(color: Colors.black, fontSize: 14, fontFamily: 'monospace')),
                ],
              ),
            )).toList(),
            const SizedBox(height: 10),
            const Text("--------------------------------", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("TOTAL:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'monospace')), Text("${NumberFormat("#,##0").format(total)} LAK", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'monospace'))]),
            const SizedBox(height: 30),
            const Text("THANK YOU", style: TextStyle(fontSize: 16, letterSpacing: 5, color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
              child: const Text("CLOSE"),
            )
          ],
        ),
      );
    }
  );
}
