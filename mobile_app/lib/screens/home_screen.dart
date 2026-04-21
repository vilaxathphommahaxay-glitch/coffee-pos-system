import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/theme.dart';
import '../core/models.dart';
import '../services/offline_db.dart';

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
  int _pollingInterval = 10; 
  
  String selectedCategory = "All";
  final List<String> categories = ["All", "Coffee", "Tea", "Dessert", "Other", "About CEO"];
  
  final String serverUrl = "http://192.168.1.50:8000";

  @override
  void initState() {
    super.initState();
    fetchProducts();
    _startSmartPolling();
  }

  @override
  void dispose() {
    _serverCheckTimer?.cancel();
    super.dispose();
  }

  void _startSmartPolling() {
    _serverCheckTimer?.cancel();
    _checkConnection();
    _serverCheckTimer = Timer.periodic(Duration(seconds: _pollingInterval), (timer) {
      _checkConnection();
    });
  }

  Future<void> _checkConnection() async {
    try {
      final response = await http.get(Uri.parse(serverUrl)).timeout(const Duration(seconds: 2));
      bool currentStatus = response.statusCode == 200;
      
      if (mounted) {
        setState(() { 
          isServerOnline = currentStatus;
          int nextInterval = isServerOnline ? 10 : 30;
          if (nextInterval != _pollingInterval) {
            _pollingInterval = nextInterval;
            _startSmartPolling();
          }
        });
        if (isServerOnline) syncOfflineOrders();
      }
    } catch (_) {
      if (mounted) {
        setState(() { 
          isServerOnline = false; 
          if (_pollingInterval != 30) {
            _pollingInterval = 30;
            _startSmartPolling();
          }
        });
      }
    }
  }

  Future<void> _updateLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_products', json.encode(products.map((p) => p.toJson()).toList()));
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
      String dbId = row['id'];
      try {
        var orderData = json.decode(row['payload']);
        orderData.remove('id'); 
        orderData.remove('created_at');
        var response = await http.post(
          Uri.parse('$serverUrl/orders'), 
          headers: {"Content-Type": "application/json"}, 
          body: json.encode(orderData)
        ).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          await OfflineDBHelper.instance.deleteOrder(dbId);
        }
      } catch (e) {
        debugPrint("Sync failed for $dbId: $e");
      }
    }
    setState(() => isSyncing = false);
  }

  Future<void> fetchProducts() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance(); 
    String? cachedData = prefs.getString('cached_products');
    
    if (cachedData != null && cachedData.isNotEmpty) {
      List decoded = json.decode(cachedData);
      setState(() {
        products = decoded.map((p) => ProductModel.fromJson(p)).toList();
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
        await prefs.setString('cached_products', responseBody); 
      } else { 
        throw Exception("Server Error");
      }
    } catch (e) { 
      setState(() { isLoading = false; isServerOnline = false; });
    }
  }

  void addToCart(ProductModel product, String type, String sweet, String note, double finalPrice) {
    setState(() {
      int productIndex = products.indexWhere((p) => p.id == product.id);
      if (productIndex != -1) {
        if (products[productIndex].stock > 0) {
          var p = products[productIndex];
          products[productIndex] = ProductModel(
            id: p.id, name: p.name, price: p.price, category: p.category, 
            stock: p.stock - 1, image: p.image
          );
          _updateLocalCache(); 
        } else {
          showSoftSnackbar("⚠️ ສິນຄ້າໝົດສະຕ໋ອກ!");
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

  void decreaseQty(int index) { setState(() { if (cart[index].qty > 1) { cart[index].qty--; } else { cart.removeAt(index); } }); }
  void increaseQty(int index) { setState(() { cart[index].qty++; }); }

  void showSoftSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'serif', fontSize: 16)),
      backgroundColor: Theme.of(context).colorScheme.onSurface, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), duration: const Duration(seconds: 2),
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
    final fmt = NumberFormat("#,##0");
    double totalCartPrice = cart.fold(0.0, (sum, item) => sum + (item.price * item.qty));
    int totalItems = cart.fold(0, (sum, item) => sum + item.qty);
    
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth > 900 ? 5 : (screenWidth > 600 ? 3 : 2);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            _ConnectionLamp(isServerOnline: isServerOnline),
            const SizedBox(width: 10),
            const Text("ILa HomeBar&Coffee☕"),
          ],
        ), 
        actions: [
          IconButton(onPressed: widget.toggleTheme, icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.receipt_long)), 
          IconButton(onPressed: fetchProducts, icon: const Icon(Icons.refresh)), 
        ]
      ),
      body: Column(
        children: [
          _CategoryBar(
            categories: categories, 
            selectedCategory: selectedCategory, 
            onSelected: (c) => setState(() => selectedCategory = c)
          ),
          Expanded(
            child: isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : GridView.builder(
                  padding: const EdgeInsets.all(15), 
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.8, 
                    crossAxisSpacing: 12, 
                    mainAxisSpacing: 12
                  ), 
                  itemCount: products.where((p) => selectedCategory == "All" || p.category == selectedCategory).length, 
                  itemBuilder: (context, index) {
                    final filteredProducts = products.where((p) => selectedCategory == "All" || p.category == selectedCategory).toList();
                    final item = filteredProducts[index];
                    return _ProductCard(
                      item: item, 
                      onTap: () => addToCart(item, "Iced", "100%", "", item.price), // Simplified for speed
                      categoryIcon: getCategoryIcon(item.category),
                    );
                  }
                )
          )
        ],
      ),
      bottomNavigationBar: cart.isEmpty ? null : _CartBottomBar(
        totalItems: totalItems, 
        totalPrice: totalCartPrice,
        onPay: () => setState(() => cart.clear()),
      ),
    );
  }
}

// 🚀 --- High Performance UI Components ---

class _ConnectionLamp extends StatelessWidget {
  final bool isServerOnline;
  const _ConnectionLamp({required this.isServerOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12, height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isServerOnline ? Colors.green : Colors.red,
        boxShadow: [BoxShadow(color: (isServerOnline ? Colors.green : Colors.red).withOpacity(0.5), blurRadius: 4)]
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onSelected;

  const _CategoryBar({required this.categories, required this.selectedCategory, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 60, 
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final c = categories[index];
          bool isSelected = selectedCategory == c;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: FilterChip(
              label: Text(c, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              selected: isSelected,
              onSelected: (_) => onSelected(c),
              selectedColor: colorScheme.primary,
              checkmarkColor: Colors.white,
            ),
          );
        },
      ),
    );
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
    bool isOutOfStock = item.stock <= 0;

    return GestureDetector(
      onTap: isOutOfStock ? null : onTap,
      child: Card(
        elevation: 0,
        color: isOutOfStock ? Colors.grey[200] : colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), border: Border.all(color: colorScheme.outline)),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: item.image.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        memCacheHeight: 250, // 🚀 ประหยัด RAM
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        errorWidget: (context, url, error) => Icon(categoryIcon, size: 40, color: colorScheme.primary),
                      )
                    : Icon(categoryIcon, size: 40, color: colorScheme.primary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text("${NumberFormat("#,##0").format(item.price)} กีบ", style: TextStyle(color: colorScheme.secondary, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return BottomAppBar(
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("$totalItems Items", style: const TextStyle(fontSize: 12)),
              Text("${NumberFormat("#,##0").format(totalPrice)} LAK", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          ElevatedButton(
            onPressed: onPay,
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
            child: const Text("PAY NOW", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}
