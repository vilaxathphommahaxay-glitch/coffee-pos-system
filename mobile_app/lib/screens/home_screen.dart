import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/theme.dart';
import '../core/models.dart';
import '../services/offline_db.dart';
import 'barista_screen.dart';
import '../widgets/admin_pin_dialog.dart';
import 'admin_menu_screen.dart';
import 'dashboard_screen.dart';
import 'kanban_board_screen.dart';
import 'transaction_history_screen.dart';
import '../widgets/receipt_sheet.dart';

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
  bool isMockMode = true; // 🧪 Mock Mode Enabled for development
  List<CartItem> heldCart = []; // 📦 Held Order Storage

  final List<ProductModel> mockProducts = [
    ProductModel(id: 101, name: "Espresso", price: 15000, category: "Coffee", stock: 99, image: ""),
    ProductModel(id: 102, name: "Latte", price: 25000, category: "Coffee", stock: 99, image: ""),
    ProductModel(id: 103, name: "Dirty Coffee", price: 30000, category: "Coffee", stock: 99, image: ""),
    ProductModel(id: 104, name: "Iced Americano", price: 20000, category: "Coffee", stock: 99, image: ""),
    ProductModel(id: 105, name: "Matcha Latte", price: 28000, category: "Tea", stock: 99, image: ""),
    ProductModel(id: 106, name: "Croissant", price: 22000, category: "Dessert", stock: 99, image: ""),
  ];
  
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
    if (isMockMode) {
      setState(() {
        products = mockProducts;
        isLoading = false;
        isServerOnline = false; // Stay red in mock mode
      });
      return;
    }

    setState(() => isLoading = true);
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
        await box.put('items', decoded);
      }
    } catch (e) { 
      setState(() { isLoading = false; isServerOnline = false; });
    }
  }

  void showBaristaTimer() {
    Stopwatch stopwatch = Stopwatch();
    Timer? timer;
    String formattedTime = "00:00.0";

    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setTimerState) {
            void startTimer() {
              stopwatch.start();
              timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
                final duration = stopwatch.elapsed;
                final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
                final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
                final tenths = (duration.inMilliseconds.remainder(1000) / 100).floor();
                setTimerState(() {
                  formattedTime = "$minutes:$seconds.$tenths";
                });
              });
            }

            void stopTimer() {
              stopwatch.stop();
              timer?.cancel();
              setTimerState(() {});
            }

            void resetTimer() {
              stopwatch.reset();
              setTimerState(() {
                formattedTime = "00:00.0";
              });
            }

            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.orange),
                  const SizedBox(width: 10),
                  const Text("Barista Timer"),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formattedTime,
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: stopwatch.isRunning ? stopTimer : startTimer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: stopwatch.isRunning ? Colors.redAccent : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(stopwatch.isRunning ? "STOP" : "START"),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: resetTimer,
                        child: const Text("RESET"),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    timer?.cancel();
                    Navigator.pop(context);
                  },
                  child: const Text("CLOSE"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ☕ Enhanced AddToCart for Slow Bar
  void addToCart(ProductModel product, String type, String sweet, String note, double finalPrice, {String bean = "House Blend", String milk = "Normal", String brew = "Espresso"}) {
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

      var existingIndex = cart.indexWhere((item) => 
        item.productId == product.id && item.type == type && item.sweet == sweet && item.bean == bean && item.milk == milk && item.brewMethod == brew);
      
      if (existingIndex != -1) { 
        cart[existingIndex].qty++; 
      } else { 
        cart.add(CartItem(
          productId: product.id, name: product.name, price: finalPrice, qty: 1, 
          type: type, sweet: sweet, note: note, category: product.category,
          bean: bean, milk: milk, brewMethod: brew
        )); 
      }
    });
  }

  void _showOptionModal(ProductModel product) {
    String selectedType = "Iced";
    String selectedSweet = "100%";
    String selectedBean = "House Blend";
    String selectedMilk = "Normal";
    String selectedBrew = "Espresso";
    TextEditingController noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          double extraCost = 0;
          if (selectedBean == "Thai") extraCost += 5000;
          if (selectedBean == "Ethiopia") extraCost += 15000;
          if (selectedMilk == "Oat Milk") extraCost += 10000;
          if (selectedMilk == "Almond Milk") extraCost += 20000;
          double finalPrice = product.price + extraCost;

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            ),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 15),
                  Text(product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text("${NumberFormat("#,##0").format(finalPrice)} LAK", style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                  const Divider(height: 30),

                  if (product.category == "Coffee") ...[
                    _buildOptionTitle("Temperature"),
                    _buildChoiceChips(["Hot", "Iced"], selectedType, (val) => setModalState(() => selectedType = val)),
                    
                    _buildOptionTitle("Coffee Bean"),
                    _buildChoiceChips(["House Blend", "Thai (+5k)", "Ethiopia (+15k)"], 
                      selectedBean == "Thai" ? "Thai (+5k)" : (selectedBean == "Ethiopia" ? "Ethiopia (+15k)" : "House Blend"), 
                      (val) => setModalState(() => selectedBean = val.contains("Thai") ? "Thai" : (val.contains("Ethiopia") ? "Ethiopia" : "House Blend"))),

                    _buildOptionTitle("Brew Method"),
                    _buildChoiceChips(["Espresso", "Flair", "V60", "Aeropress"], selectedBrew, (val) => setModalState(() => selectedBrew = val)),
                  ],

                  if (product.category == "Coffee" || product.category == "Tea") ...[
                    _buildOptionTitle("Sweetness"),
                    _buildChoiceChips(["0%", "25%", "50%", "100%"], selectedSweet, (val) => setModalState(() => selectedSweet = val)),

                    _buildOptionTitle("Milk Alternative"),
                    _buildChoiceChips(["Normal", "Oat Milk (+10k)", "Almond Milk (+20k)"], 
                      selectedMilk == "Oat Milk" ? "Oat Milk (+10k)" : (selectedMilk == "Almond Milk" ? "Almond Milk (+20k)" : "Normal"), 
                      (val) => setModalState(() => selectedMilk = val.contains("Oat") ? "Oat Milk" : (val.contains("Almond") ? "Almond Milk" : "Normal"))),
                  ],

                  _buildOptionTitle("Note"),
                  TextField(controller: noteCtrl, decoration: const InputDecoration(hintText: "Special instructions...", border: OutlineInputBorder())),

                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      addToCart(product, selectedType, selectedSweet, noteCtrl.text, finalPrice, bean: selectedBean, milk: selectedMilk, brew: selectedBrew);
                      Navigator.pop(context);
                      showSoftSnackbar("Added to Cart!");
                    },
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    child: const Text("ADD TO CART", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildOptionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(top: 20, bottom: 10), child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)));
  }

  Widget _buildChoiceChips(List<String> options, String selected, Function(String) onSelected) {
    return Wrap(
      spacing: 8,
      children: options.map((opt) {
        bool isSelected = selected == opt;
        return ChoiceChip(
          label: Text(opt),
          selected: isSelected,
          onSelected: (_) => onSelected(opt),
          selectedColor: Theme.of(context).colorScheme.primary,
          labelStyle: TextStyle(color: isSelected ? Colors.white : null),
        );
      }).toList(),
    );
  }

  // --- UI Components below ---

  // 🛒 Cart Management
  void updateCartItemQty(int index, int delta) {
    setState(() {
      cart[index].qty += delta;
      if (cart[index].qty <= 0) {
        cart.removeAt(index);
      }
    });
  }

  void removeCartItem(int index) {
    setState(() {
      cart.removeAt(index);
    });
  }

  void holdOrder() {
    if (cart.isEmpty) return;
    setState(() {
      heldCart = List.from(cart);
      cart.clear();
    });
    showSoftSnackbar("Order Held 📦");
  }

  void recallOrder() {
    if (heldCart.isEmpty) return;
    setState(() {
      cart = List.from(heldCart);
      heldCart.clear();
    });
    showSoftSnackbar("Order Recalled 📥");
  }

  void showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          double total = cart.fold(0.0, (sum, item) => sum + (item.price * item.qty));
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 15),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("MY CART", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          if (heldCart.isNotEmpty)
                            TextButton.icon(
                              onPressed: () { recallOrder(); setSheetState(() {}); },
                              icon: Badge(label: Text("${heldCart.length}"), child: const Icon(Icons.history, color: Colors.orange)),
                              label: const Text("RECALL", style: TextStyle(color: Colors.orange)),
                            ),
                          const SizedBox(width: 10),
                          IconButton(
                            onPressed: cart.isEmpty ? null : () { holdOrder(); Navigator.pop(context); },
                            icon: const Icon(Icons.pause_circle_outline, color: Colors.blue),
                            tooltip: "Hold Order",
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: cart.isEmpty 
                    ? const Center(child: Text("Cart is empty"))
                    : ListView.builder(
                        itemCount: cart.length,
                        itemBuilder: (context, index) {
                          final item = cart[index];
                          String modifiers = "${item.type}, ${item.sweet}";
                          if (item.category == "Coffee") modifiers += ", ${item.bean}, ${item.brewMethod}";
                          if (item.milk != "Normal") modifiers += ", ${item.milk}";

                          return Dismissible(
                            key: UniqueKey(),
                            background: Container(
                              color: Colors.green,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20),
                              child: const Icon(Icons.copy, color: Colors.white),
                            ),
                            secondaryBackground: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                setState(() {
                                  cart.insert(index + 1, item.copyWith(qty: 1));
                                });
                                setSheetState(() {});
                                showSoftSnackbar("Item Duplicated");
                                return false; // Don't dismiss
                              }
                              return true; // Delete
                            },
                            onDismissed: (direction) {
                              if (direction == DismissDirection.endToStart) {
                                removeCartItem(index);
                                setSheetState(() {});
                                if (cart.isEmpty) Navigator.pop(context);
                              }
                            },
                            child: ListTile(
                              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(modifiers, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                  if (item.note.isNotEmpty) Text("Note: ${item.note}", style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("${NumberFormat("#,##0").format(item.price * item.qty)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 10),
                                  Container(
                                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      children: [
                                        IconButton(icon: const Icon(Icons.remove, size: 16), onPressed: () { updateCartItemQty(index, -1); setSheetState(() {}); if (cart.isEmpty) Navigator.pop(context); }),
                                        Text("${item.qty}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                        IconButton(icon: const Icon(Icons.add, size: 16), onPressed: () { updateCartItemQty(index, 1); setSheetState(() {}); }),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: ElevatedButton(
                    onPressed: cart.isEmpty ? null : () {
                      Navigator.pop(context);
                      showPaymentDialog();
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("CHECKOUT", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 15),
                        Text("${NumberFormat("#,##0").format(total)} LAK", style: const TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        }
      ),
    );
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
                Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), backgroundColor: Colors.green), onPressed: () { Navigator.pop(context); showChangeCalculator(total); }, icon: const Icon(Icons.money, color: Colors.white), label: const Text("CASH", style: TextStyle(color: Colors.white)))),
                const SizedBox(width: 15),
                Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), backgroundColor: Colors.blue), onPressed: () { Navigator.pop(context); showDynamicQR(total); }, icon: const Icon(Icons.qr_code_scanner, color: Colors.white), label: const Text("QR SCAN", style: TextStyle(color: Colors.white)))),
              ],
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), backgroundColor: Colors.purple, minimumSize: const Size(double.infinity, 50)),
              onPressed: () { Navigator.pop(context); showAdvancedSplitBillDialog(total); },
              icon: const Icon(Icons.call_split, color: Colors.white),
              label: const Text("ADVANCED SPLIT BILL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void showAdvancedSplitBillDialog(double total) {
    int splitWays = 2;
    List<CartItem> selectedItemsForSplit = [];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return DefaultTabController(
            length: 2,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 15),
                  const Text("Split Bill", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TabBar(
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    tabs: const [
                      Tab(text: "Split Evenly"),
                      Tab(text: "Split by Item"),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Split Evenly Tab
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Total: ${NumberFormat("#,##0").format(total)} LAK", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 30),
                              Text("Split $splitWays ways", style: const TextStyle(fontSize: 18)),
                              Slider(
                                value: splitWays.toDouble(),
                                min: 2,
                                max: 10,
                                divisions: 8,
                                label: splitWays.toString(),
                                activeColor: Theme.of(context).colorScheme.primary,
                                onChanged: (val) {
                                  setModalState(() => splitWays = val.toInt());
                                },
                              ),
                              const SizedBox(height: 30),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Column(
                                  children: [
                                    const Text("Each Person Pays", style: TextStyle(fontSize: 16, color: Colors.grey)),
                                    const SizedBox(height: 10),
                                    Text("${NumberFormat("#,##0").format(total / splitWays)} LAK", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  showChangeCalculator(total / splitWays);
                                },
                                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                                child: const Text("PAY ONE SHARE"),
                              )
                            ],
                          ),
                        ),
                        // Split by Item Tab
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Text("Select items for Sub-Bill 1", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: cart.length,
                                  itemBuilder: (context, index) {
                                    final item = cart[index];
                                    final isSelected = selectedItemsForSplit.contains(item);
                                    return CheckboxListTile(
                                      title: Text("${item.qty}x ${item.name}"),
                                      subtitle: Text("${NumberFormat("#,##0").format(item.price * item.qty)} LAK"),
                                      value: isSelected,
                                      activeColor: Theme.of(context).colorScheme.primary,
                                      onChanged: (val) {
                                        setModalState(() {
                                          if (val == true) {
                                            selectedItemsForSplit.add(item);
                                          } else {
                                            selectedItemsForSplit.remove(item);
                                          }
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Sub-Bill Total:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Text("${NumberFormat("#,##0").format(selectedItemsForSplit.fold(0.0, (sum, item) => sum + (item.price * item.qty)))} LAK", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                ],
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: selectedItemsForSplit.isEmpty ? null : () {
                                  Navigator.pop(context);
                                  double subTotal = selectedItemsForSplit.fold(0.0, (sum, item) => sum + (item.price * item.qty));
                                  showChangeCalculator(subTotal);
                                },
                                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                                child: const Text("PAY SUB-BILL"),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void showChangeCalculator(double total) {
    TextEditingController amountCtrl = TextEditingController();
    double change = 0.0;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void updateAmount(double amount) {
            amountCtrl.text = amount.toInt().toString();
            setDialogState(() {
              change = amount >= total ? amount - total : 0;
            });
          }

          return AlertDialog(
            title: const Text("Cash Payment"),
            content: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Total Payable: ${NumberFormat("#,##0").format(total)} LAK", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(labelText: "Amount Received", border: OutlineInputBorder(), suffixText: "LAK"),
                      onChanged: (val) {
                        double received = double.tryParse(val) ?? 0;
                        setDialogState(() => change = received >= total ? received - total : 0);
                      },
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        _quickCashButton("Exact", total, updateAmount),
                        _quickCashButton("50k", 50000, updateAmount),
                        _quickCashButton("100k", 100000, updateAmount),
                        _quickCashButton("200k", 200000, updateAmount),
                        _quickCashButton("500k", 500000, updateAmount),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text("CHANGE DUE", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                    Text("${NumberFormat("#,##0").format(change)} LAK", style: const TextStyle(fontSize: 36, color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _finalizeOrder("CASH", total, phoneCtrl.text);
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size(100, 50)),
                child: const Text("DONE"),
              )
            ],
          );
        }
      ),
    );
  }

  Widget _quickCashButton(String label, double amount, Function(double) onTap) {
    return ElevatedButton(
      onPressed: () => onTap(amount),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[200],
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      ),
      child: Text(label),
    );
  }

  void showDynamicQR(double total) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Scan to Pay"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text("Total: ${NumberFormat("#,##0").format(total)} LAK", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(width: 200, height: 200, child: QrImageView(data: "LAK:$total", version: QrVersions.auto, size: 200.0)),
          const SizedBox(height: 10),
          const Text("Please show this to the customer", style: TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")), ElevatedButton(onPressed: () { Navigator.pop(context); _finalizeOrder("QR_SCAN", total, phoneCtrl.text); }, child: const Text("PAYMENT DONE"))],
      ),
    );
  }

  void _finalizeOrder(String method, double total, String phone) async {
    final orderData = {
      "total_amount": total,
      "payment_method": method,
      "customer_phone": phone,
      "items": cart.map((i) => i.toJson()).toList()
    };
    
    // In Mock Mode, we skip real API but still save offline for persistence if needed
    if (!isMockMode) {
      if (isServerOnline) {
        try { await http.post(Uri.parse('$serverUrl/orders'), headers: {"Content-Type": "application/json"}, body: json.encode(orderData)); } catch (_) { await saveOrderOffline(orderData); }
      } else { await saveOrderOffline(orderData); }
    } else {
      // Mock persistence
      await saveOrderOffline(orderData);
    }
    
    setState(() { 
      cart.clear(); 
      phoneCtrl.clear(); 
    });
    
    _showSuccessDialog();

    // 🧾 Automatically show digital receipt after a short delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) showDigitalReceipt(context, orderData);
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 100),
                const SizedBox(height: 20),
                const Text("Payment Successful!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text("Order has been placed.", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("NEXT CUSTOMER"),
                )
              ],
            ),
          ),
        );
      }
    );
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
        orderData.remove('id'); orderData.remove('created_at');
        var response = await http.post(Uri.parse('$serverUrl/orders'), headers: {"Content-Type": "application/json"}, body: json.encode(orderData)).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) await OfflineDBHelper.instance.deleteOrder(row['id']);
      } catch (_) {}
    }
    setState(() => isSyncing = false);
  }

  void showSoftSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Theme.of(context).colorScheme.onSurface, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
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
        title: Row(children: [_ConnectionLamp(isServerOnline: isServerOnline), const SizedBox(width: 10), const Text("ILa HomeBar☕")]), 
        actions: [
          IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const KanbanBoardScreen())), icon: const Icon(Icons.view_kanban, color: Colors.purpleAccent)), // 📋 Order Queue
          IconButton(onPressed: showBaristaTimer, icon: const Icon(Icons.timer_outlined, color: Colors.orange)), // ⏱️ Barista Timer
          IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DashboardScreen())), icon: const Icon(Icons.bar_chart, color: Colors.blueAccent)), // 📊 Dashboard
          IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionHistoryScreen())), icon: const Icon(Icons.history, color: Colors.tealAccent)), // 📜 History
          IconButton(onPressed: () { showDialog(context: context, builder: (context) => AdminPinDialog(onAuthenticated: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => AdminMenuScreen(initialProducts: products))); fetchProducts(); })); }, icon: const Icon(Icons.settings, color: Colors.grey)),
          IconButton(onPressed: widget.toggleTheme, icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode)),
          IconButton(onPressed: fetchProducts, icon: const Icon(Icons.refresh)), 
        ]
      ),
      body: Column(children: [
        _CategoryBar(categories: categories, selectedCategory: selectedCategory, onSelected: (c) => setState(() => selectedCategory = c)),
        Expanded(child: isLoading ? const Center(child: CircularProgressIndicator()) : GridView.builder(padding: const EdgeInsets.all(15), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, childAspectRatio: 0.8, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: products.where((p) => selectedCategory == "All" || p.category == selectedCategory).length, itemBuilder: (context, index) {
          final filteredProducts = products.where((p) => selectedCategory == "All" || p.category == selectedCategory).toList();
          final item = filteredProducts[index];
          return _ProductCard(item: item, onTap: () => _showOptionModal(item), categoryIcon: getCategoryIcon(item.category));
        }))
      ]),
      bottomNavigationBar: cart.isEmpty ? null : _CartBottomBar(
        totalItems: totalItems, 
        totalPrice: totalCartPrice, 
        onPay: showCartSheet,
      ),
    );
  }
}

class _ConnectionLamp extends StatelessWidget {
  final bool isServerOnline;
  const _ConnectionLamp({required this.isServerOnline});
  @override
  Widget build(BuildContext context) { return Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: isServerOnline ? Colors.green : Colors.red, boxShadow: [BoxShadow(color: (isServerOnline ? Colors.green : Colors.red).withOpacity(0.5), blurRadius: 4)])); }
}

class _CategoryBar extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onSelected;
  const _CategoryBar({required this.categories, required this.selectedCategory, required this.onSelected});
  @override
  Widget build(BuildContext context) { return Container(height: 60, padding: const EdgeInsets.symmetric(vertical: 8), child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: categories.length, itemBuilder: (context, index) { final c = categories[index]; bool isSelected = selectedCategory == c; return Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: FilterChip(label: Text(c, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)), selected: isSelected, onSelected: (_) => onSelected(c), selectedColor: Theme.of(context).colorScheme.primary, checkmarkColor: Colors.white)); })); }
}

class _ProductCard extends StatelessWidget {
  final ProductModel item;
  final VoidCallback onTap;
  final IconData categoryIcon;
  const _ProductCard({required this.item, required this.onTap, required this.categoryIcon});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    bool isLowStock = item.stock < 5;
    return GestureDetector(onTap: item.stock <= 0 ? null : onTap, child: Card(elevation: 0, color: item.stock <= 0 ? Colors.grey[200] : colorScheme.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isLowStock ? Colors.orange : colorScheme.outline, width: isLowStock ? 2 : 1)), child: Column(children: [Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: item.image.isNotEmpty ? CachedNetworkImage(imageUrl: item.image, fit: BoxFit.cover, width: double.infinity, memCacheHeight: 250, placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)), errorWidget: (context, url, error) => Icon(categoryIcon, size: 40, color: colorScheme.primary)) : Icon(categoryIcon, size: 40, color: colorScheme.primary))), Padding(padding: const EdgeInsets.all(8.0), child: Column(children: [Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis), Text("${NumberFormat("#,##0").format(item.price)} กีบ", style: TextStyle(color: colorScheme.secondary, fontSize: 12, fontWeight: FontWeight.bold)), if (isLowStock) Text("Stock: ${item.stock}g", style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold))]))])));
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
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text("PAY NOW", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}
