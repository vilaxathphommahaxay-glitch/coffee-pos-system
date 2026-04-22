import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../core/theme.dart';
import '../core/models.dart';
import '../services/offline_db.dart';
import 'barista_screen.dart';

class PosScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;
  const PosScreen({super.key, required this.isDarkMode, required this.toggleTheme});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  List<ProductModel> products = [];
  List<CartItem> cart = [];
  bool isLoading = false;
  bool isServerOnline = false;
  bool isSyncing = false;
  
  Timer? _serverCheckTimer;
  
  String selectedCategory = "All";
  final List<String> categories = ["All", "Coffee", "Tea", "Dessert", "Other", "About CEO"];
  
  final String serverUrl = "http://100.107.25.103:8000";
  final TextEditingController phoneCtrl = TextEditingController(); // 🥇 Loyalty Phone

  @override
  void initState() {
    super.initState();
    fetchProducts();
    _startHealthCheck();
  }

  @override
  void dispose() {
    _serverCheckTimer?.cancel();
    phoneCtrl.dispose();
    super.dispose();
  }

  void _startHealthCheck() {
    _serverCheckTimer?.cancel();
    _checkConnection();
    _serverCheckTimer = Timer.periodic(const Duration(seconds: 15), (_) => _checkConnection());
  }

  Future<void> _checkConnection() async {
    try {
      final response = await http.get(Uri.parse(serverUrl)).timeout(const Duration(seconds: 2));
      if (mounted) {
        setState(() => isServerOnline = response.statusCode == 200);
        if (isServerOnline) syncOfflineOrders();
      }
    } catch (_) {
      if (mounted) setState(() => isServerOnline = false);
    }
  }

  Future<void> fetchProducts() async {
    setState(() => isLoading = true);
    
    // 🚀 Phase 3: High-Speed Hive Cache
    var box = Hive.box('productBox');
    if (box.isNotEmpty) {
      final cachedList = box.get('items') as List;
      setState(() {
        products = cachedList.map((p) => ProductModel.fromJson(Map<String, dynamic>.from(p))).toList();
      });
    }

    try {
      var response = await http.get(Uri.parse('$serverUrl/products')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        String responseBody = utf8.decode(response.bodyBytes);
        List decoded = json.decode(responseBody);
        setState(() { 
          products = decoded.map((p) => ProductModel.fromJson(p)).toList(); 
          isServerOnline = true;
          isLoading = false; 
        });
        await box.put('items', decoded); // Save to Hive
      }
    } catch (e) { 
      setState(() { isLoading = false; isServerOnline = false; });
    }
  }

  // ☕ Phase 3: Brew Method Logic
  void addToCart(ProductModel product, String type, String sweet, String note, double finalPrice) {
    setState(() {
      int productIndex = products.indexWhere((p) => p.id == product.id);
      if (productIndex != -1) {
        if (products[productIndex].stock > 0) {
          products[productIndex] = ProductModel(
            id: products[productIndex].id, name: products[productIndex].name, 
            price: products[productIndex].price, category: products[productIndex].category, 
            stock: products[productIndex].stock - 1, image: products[productIndex].image
          );
        } else {
          showSoftSnackbar("⚠️ Out of Stock!");
          return;
        }
      }

      var existingIndex = cart.indexWhere((item) => item.productId == product.id && item.type == type && item.sweet == sweet);
      if (existingIndex != -1) { 
        cart[existingIndex].qty++; 
      } else { 
        cart.add(CartItem(productId: product.id, name: product.name, price: finalPrice, qty: 1, type: type, sweet: sweet, note: note, category: product.category)); 
      }
    });
  }

  void showPaymentDialog() {
    double total = cart.fold(0.0, (sum, item) => sum + (item.price * item.qty));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("CHECKOUT", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "🥇 Loyalty Phone (Optional)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.star)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), backgroundColor: Colors.green),
                    onPressed: () {
                      Navigator.pop(context);
                      showChangeCalculator(total);
                    },
                    icon: const Icon(Icons.money, color: Colors.white),
                    label: const Text("CASH", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), backgroundColor: Colors.blue),
                    onPressed: () {
                      Navigator.pop(context);
                      showDynamicQR(total);
                    },
                    icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                    label: const Text("QR SCAN", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void showChangeCalculator(double total) {
    TextEditingController amountCtrl = TextEditingController();
    double change = 0.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Cash Payment"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Total Payable: ${NumberFormat("#,##0").format(total)} LAK", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(labelText: "Amount Received", border: OutlineInputBorder(), suffixText: "LAK"),
                onChanged: (val) {
                  double received = double.tryParse(val) ?? 0;
                  setDialogState(() => change = received >= total ? received - total : 0);
                },
              ),
              const SizedBox(height: 20),
              Text("Change Due: ${NumberFormat("#,##0").format(change)} LAK", style: const TextStyle(fontSize: 22, color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _finalizeOrder("CASH", total, phoneCtrl.text);
              },
              child: const Text("DONE"),
            ),
          ],
        ),
      ),
    );
  }

  void showDynamicQR(double total) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Scan to Pay"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Total: ${NumberFormat("#,##0").format(total)} LAK", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(data: "LAK:$total", version: QrVersions.auto, size: 200.0),
            ),
            const SizedBox(height: 10),
            const Text("Please show this to the customer", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _finalizeOrder("QR_SCAN", total, phoneCtrl.text);
            },
            child: const Text("PAYMENT DONE"),
          ),
        ],
      ),
    );
  }

  void _finalizeOrder(String method, double total, String phone) async {
    final orderData = {
      "total_amount": total,
      "payment_method": method,
      "customer_phone": phone, // 🥇 Loyalty Phone included
      "items": cart.map((i) => {
        "product_id": i.productId,
        "product_name": i.name,
        "quantity": i.qty,
        "price_at_sale": i.price,
        "sweetness": i.sweet,
        "item_type": i.type,
        "note": i.note
      }).toList()
    };

    printReceipt(orderData);

    if (isServerOnline) {
      try {
        await http.post(Uri.parse('$serverUrl/orders'), headers: {"Content-Type": "application/json"}, body: json.encode(orderData));
      } catch (_) {
        await saveOrderOffline(orderData);
      }
    } else {
      await saveOrderOffline(orderData);
    }

    setState(() {
      cart.clear();
      phoneCtrl.clear();
    });
    showSoftSnackbar("Order Complete! ✅");
  }

  Future<void> saveOrderOffline(Map<String, dynamic> orderData) async {
    String offlineId = "OFFLINE_${DateTime.now().millisecondsSinceEpoch}";
    orderData['id'] = offlineId;
    orderData['created_at'] = DateTime.now().toIso8601String();
    await OfflineDBHelper.instance.insertOrder(offlineId, orderData);
  }

  Future<void> syncOfflineOrders() async {
    if (isSyncing) return;
    List<Map<String, dynamic>> unsyncedOrders = await OfflineDBHelper.instance.getUnsyncedOrders();
    if (unsyncedOrders.isEmpty) return;
    setState(() => isSyncing = true);
    for (var row in unsyncedOrders) {
      try {
        var orderData = json.decode(row['payload']);
        orderData.remove('id'); 
        orderData.remove('created_at');
        var response = await http.post(Uri.parse('$serverUrl/orders'), headers: {"Content-Type": "application/json"}, body: json.encode(orderData)).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) await OfflineDBHelper.instance.deleteOrder(row['id']);
      } catch (_) {}
    }
    setState(() => isSyncing = false);
  }

  void printReceipt(Map<String, dynamic> orderData) async {
    debugPrint("--- Receipt Data: $orderData ---");
  }

  void showSoftSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: Theme.of(context).colorScheme.onSurface, behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Coffee': return Icons.coffee;
      case 'Tea': return Icons.emoji_food_beverage;
      case 'Dessert': return Icons.cake;
      case 'Other': return Icons.local_drink;
      default: return Icons.fastfood;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    double totalCartPrice = cart.fold(0.0, (sum, item) => sum + (item.price * item.qty));
    int totalItems = cart.fold(0, (sum, item) => sum + item.qty);
    
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth > 900 ? 5 : (screenWidth > 600 ? 3 : 2);

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          _ConnectionLamp(isServerOnline: isServerOnline),
          const SizedBox(width: 10),
          const Text("ILa HomeBar&Coffee☕"),
        ]), 
        actions: [
          IconButton(onPressed: widget.toggleTheme, icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode)),
          IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BaristaScreen())), icon: const Icon(Icons.coffee_maker_outlined, color: Colors.orangeAccent)), 
          IconButton(onPressed: fetchProducts, icon: const Icon(Icons.refresh)), 
        ]
      ),
      body: Column(
        children: [
          _CategoryBar(categories: categories, selectedCategory: selectedCategory, onSelected: (c) => setState(() => selectedCategory = c)),
          Expanded(
            child: isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : GridView.builder(
                  padding: const EdgeInsets.all(15), 
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, childAspectRatio: 0.8, crossAxisSpacing: 12, mainAxisSpacing: 12), 
                  itemCount: products.where((p) => selectedCategory == "All" || p.category == selectedCategory).length, 
                  itemBuilder: (context, index) {
                    final filteredProducts = products.where((p) => selectedCategory == "All" || p.category == selectedCategory).toList();
                    final item = filteredProducts[index];
                    return _ProductCard(
                      item: item, 
                      onTap: () => addToCart(item, "Iced", "100%", "", item.price), 
                      categoryIcon: getCategoryIcon(item.category),
                    );
                  }
                )
          )
        ],
      ),
      bottomNavigationBar: cart.isEmpty ? null : _CartBottomBar(totalItems: totalItems, totalPrice: totalCartPrice, onPay: showPaymentDialog),
    );
  }
}

class _ConnectionLamp extends StatelessWidget {
  final bool isServerOnline;
  const _ConnectionLamp({required this.isServerOnline});
  @override
  Widget build(BuildContext context) {
    return Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: isServerOnline ? Colors.green : Colors.red, boxShadow: [BoxShadow(color: (isServerOnline ? Colors.green : Colors.red).withOpacity(0.5), blurRadius: 4)]));
  }
}

class _CategoryBar extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onSelected;
  const _CategoryBar({required this.categories, required this.selectedCategory, required this.onSelected});
  @override
  Widget build(BuildContext context) {
    return Container(height: 60, padding: const EdgeInsets.symmetric(vertical: 8), child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: categories.length, itemBuilder: (context, index) {
      final c = categories[index]; bool isSelected = selectedCategory == c;
      return Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: FilterChip(label: Text(c, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)), selected: isSelected, onSelected: (_) => onSelected(c), selectedColor: Theme.of(context).colorScheme.primary, checkmarkColor: Colors.white));
    }));
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel item;
  final VoidCallback onTap;
  final IconData categoryIcon;
  const _ProductCard({required this.item, required this.onTap, required this.categoryIcon});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    bool isLowStock = item.stock < 5; // 🚀 Micro-Inventory Alert
    return GestureDetector(
      onTap: item.stock <= 0 ? null : onTap,
      child: Card(
        elevation: 0, color: item.stock <= 0 ? Colors.grey[200] : colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isLowStock ? Colors.orange : colorScheme.outline, width: isLowStock ? 2 : 1)),
        child: Column(
          children: [
            Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: item.image.isNotEmpty ? CachedNetworkImage(imageUrl: item.image, fit: BoxFit.cover, width: double.infinity, memCacheHeight: 250, placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)), errorWidget: (context, url, error) => Icon(categoryIcon, size: 40, color: colorScheme.primary)) : Icon(categoryIcon, size: 40, color: colorScheme.primary))),
            Padding(padding: const EdgeInsets.all(8.0), child: Column(children: [
              Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text("${NumberFormat("#,##0").format(item.price)} กีบ", style: TextStyle(color: colorScheme.secondary, fontSize: 12, fontWeight: FontWeight.bold)),
              if (isLowStock) Text("Stock: ${item.stock}g", style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
            ])),
          ],
        ),
      ),
    );
  }
}

class _CartBottomBar extends StatelessWidget {
  final int totalItems;
  final double totalPrice;
  final VoidCallback onPay;
  const _CartBottomBar({required this.totalItems, required this.totalPrice, required this.onPay});
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(height: 80, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text("$totalItems Items", style: const TextStyle(fontSize: 12)), Text("${NumberFormat("#,##0").format(totalPrice)} LAK", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
      ElevatedButton(onPressed: onPay, style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)), child: const Text("PAY NOW", style: TextStyle(fontWeight: FontWeight.bold)))
    ]));
  }
}
