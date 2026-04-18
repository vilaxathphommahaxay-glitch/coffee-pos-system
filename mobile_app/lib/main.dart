import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() { runApp(const CoffeeShopApp()); }

// 🎨 --- Color Palette (Slow Bar x Classic) ---
const Color bgCream = Color(0xFFF9F6F0);
const Color earthBrown = Color(0xFF5D4037);
const Color mossGreen = Color(0xFF6B705C);
const Color softBlack = Color(0xFF2C2C2C);
const Color paperWhite = Color(0xFFFFFFFF);
const Color borderColor = Color(0xFFE8E4D9);
const Color mutedText = Color(0xFF8D8D8D);

class CoffeeShopApp extends StatelessWidget {
  const CoffeeShopApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: bgCream,
        fontFamily: 'serif', 
        appBarTheme: const AppBarTheme(
          backgroundColor: bgCream,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: softBlack),
          titleTextStyle: TextStyle(color: softBlack, fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        colorScheme: const ColorScheme.light(primary: earthBrown, secondary: mossGreen, surface: paperWhite, onSurface: softBlack),
        useMaterial3: true,
      ),
      home: const PosScreen(),
    );
  }
}

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});
  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  List products = [];
  List<Map<String, dynamic>> cart = [];
  bool isLoading = false;
  String selectedCategory = "All";
  String errorMessage = "";
  
  final List<String> categories = ["All", "Coffee", "Tea", "Dessert", "Other", "About CEO"];
  final String serverUrl = "https://sumday-pos-backend.onrender.com/api";

  @override
  void initState() {
    super.initState();
    fetchProducts();
    syncOfflineOrders(); 
  }

  // ⚙️ --- Core Functions ---
  Future<void> saveOrderOffline(Map<String, dynamic> orderData) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> offlineOrders = prefs.getStringList('offline_orders') ?? [];
    orderData['id'] = "OFFLINE_${DateTime.now().millisecondsSinceEpoch}"; 
    orderData['created_at'] = DateTime.now().toString();
    offlineOrders.add(json.encode(orderData));
    await prefs.setStringList('offline_orders', offlineOrders);
  }

  Future<void> syncOfflineOrders() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> offlineOrders = prefs.getStringList('offline_orders') ?? [];
    if (offlineOrders.isEmpty) return;
    List<String> remainingOrders = [];
    for (String orderStr in offlineOrders) {
      try {
        var orderData = json.decode(orderStr);
        orderData.remove('id'); 
        orderData.remove('created_at'); 
        var response = await http.post(Uri.parse('$serverUrl/orders'), headers: {"Content-Type": "application/json"}, body: json.encode(orderData)).timeout(const Duration(seconds: 5));
        if (response.statusCode != 200) remainingOrders.add(orderStr);
      } catch (e) { remainingOrders.add(orderStr); }
    }
    await prefs.setStringList('offline_orders', remainingOrders);
  }

  double safeParse(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '')) ?? 0.0;
  }

  Future<void> fetchProducts() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance(); 
    String? cachedData = prefs.getString('cached_products');
    if (cachedData != null && cachedData.isNotEmpty) {
      products = json.decode(cachedData);
    }

    try {
      syncOfflineOrders(); 
      var response = await http.get(Uri.parse('$serverUrl/products')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        String responseBody = utf8.decode(response.bodyBytes);
        setState(() { products = json.decode(responseBody); isLoading = false; });
        await prefs.setString('cached_products', responseBody); 
      } else { throw Exception("Server Error"); }
    } catch (e) { 
      setState(() => isLoading = false);
      if (products.isEmpty) {
        String dummyData = '''[
          {"id": 1, "name": "Moka Pot Espresso", "price": 25000, "category": "Coffee", "stock": 99, "image": "https://images.unsplash.com/photo-1579992357154-faf4bde95b3d?auto=format&fit=crop&w=500&q=80"},
          {"id": 2, "name": "Aram Espresso", "price": 30000, "category": "Coffee", "stock": 99, "image": "https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=500&q=80"},
          {"id": 3, "name": "Hand Drip (V60)", "price": 35000, "category": "Coffee", "stock": 99, "image": "https://images.unsplash.com/photo-1497935586351-b67a49e012bf?auto=format&fit=crop&w=500&q=80"},
          {"id": 4, "name": "Dirty Coffee", "price": 30000, "category": "Coffee", "stock": 99, "image": "https://images.unsplash.com/photo-1599395878342-a9b9a696cb8d?auto=format&fit=crop&w=500&q=80"},
          {"id": 5, "name": "Matcha Latte", "price": 28000, "category": "Tea", "stock": 99, "image": "https://images.unsplash.com/photo-1515823662972-da6a2e4d3002?auto=format&fit=crop&w=500&q=80"},
          {"id": 6, "name": "Hojicha Latte", "price": 28000, "category": "Tea", "stock": 99, "image": "https://images.unsplash.com/photo-1572019992683-16a3a936a213?auto=format&fit=crop&w=500&q=80"},
          {"id": 7, "name": "Butter Croissant", "price": 20000, "category": "Dessert", "stock": 99, "image": "https://images.unsplash.com/photo-1555507036-ab1f4038808a?auto=format&fit=crop&w=500&q=80"},
          {"id": 8, "name": "Basque Cheesecake", "price": 35000, "category": "Dessert", "stock": 99, "image": "https://images.unsplash.com/photo-1606890737304-57a1ca8a5b62?auto=format&fit=crop&w=500&q=80"},
          {"id": 9, "name": "Craft Cocoa", "price": 25000, "category": "Other", "stock": 99, "image": "https://images.unsplash.com/photo-1542990253-0d0f5be5f0ed?auto=format&fit=crop&w=500&q=80"}
        ]''';
        setState(() { products = json.decode(dummyData); });
        await prefs.setString('cached_products', dummyData); 
      }
      showSoftSnackbar("📡 ໃຊ້ງານໂໝດອອຟລາຍ (Offline Mode)");
    }
  }

  Future<void> placeOrder(String paymentMethod) async {
    if (cart.isEmpty) return;
    Navigator.pop(context); 
    Navigator.pop(context); 
    
    var orderData = { 
      "total_amount": cart.fold(0.0, (sum, item) => sum + (item['price'] * item['qty'])), 
      "payment_method": paymentMethod, 
      "employee_id": 1, 
      "items": cart.map((i) => { 
        "product_id": i['id'], 
        "product_name": i['name'], 
        "quantity": i['qty'], 
        "price_at_sale": i['price'], 
        "sweetness": i['sweet'] ?? "", 
        "item_type": i['type'] ?? "", 
        "note": i['note'] ?? "" 
      }).toList() 
    };
    
    setState(() { cart.clear(); });
    showSoftSnackbar("✅ ຊຳລະເງິນສຳເລັດ! ($paymentMethod)");

    await saveOrderOffline(orderData);
    syncOfflineOrders(); 
  }

  Future<void> processRefund(dynamic orderId) async {
    final prefs = await SharedPreferences.getInstance();
    if (orderId.toString().startsWith("OFFLINE_")) {
      List<String> offlineOrders = prefs.getStringList('offline_orders') ?? [];
      offlineOrders.removeWhere((orderStr) => json.decode(orderStr)['id'] == orderId);
      await prefs.setStringList('offline_orders', offlineOrders);
      showSoftSnackbar("✅ ຍົກເລີກບິນອອຟລາຍສຳເລັດ");
      return;
    }
    try {
      var response = await http.delete(Uri.parse('$serverUrl/orders/$orderId')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) { showSoftSnackbar("✅ ຍົກເລີກບິນ ແລະ ຄືນສະຕ໋ອກແລ້ວ"); fetchProducts(); } 
      else { showSoftSnackbar("ບໍ່ສາມາດຍົກເລີກໄດ້ໃນຂະນະນີ້"); }
    } catch (e) { showSoftSnackbar("⚠️ ບໍ່ມີອິນເຕີເນັດ ບໍ່ສາມາດຍົກເລີກບິນເກົ່າໄດ້"); }
  }

  // 📝 --- ระบบจัดการเมนู (เพิ่ม/แก้/ลบ) ---
  void showAddProductDialog() { showManageProductDialog(); }

  void showManageProductDialog({Map? existingProduct, int? index}) {
    bool isEditing = existingProduct != null;
    TextEditingController nameCtrl = TextEditingController(text: isEditing ? existingProduct['name'] : "");
    TextEditingController priceCtrl = TextEditingController(text: isEditing ? existingProduct['price'].toString() : "");
    TextEditingController imageCtrl = TextEditingController(text: isEditing ? (existingProduct['image'] ?? "") : "");
    String newCategory = isEditing ? existingProduct['category'] : "Coffee";

    showModalBottomSheet(
      context: context, backgroundColor: bgCream, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isEditing ? "✏️ ແກ້ໄຂເມນູ (Edit)" : "➕ ເພີ່ມເມນູໃໝ່ (Add)", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: softBlack)),
                    if (isEditing) 
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () async {
                          setState(() { products.removeAt(index!); });
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('cached_products', json.encode(products));
                          Navigator.pop(context); 
                          Navigator.pop(context); 
                          showSoftSnackbar("🗑️ ລຶບເມນູສຳເລັດ!");
                        }
                      )
                  ],
                ),
                const SizedBox(height: 15),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "ຊື່ເມນູ (Name)", filled: true, fillColor: paperWhite, border: OutlineInputBorder(borderSide: BorderSide.none))),
                const SizedBox(height: 10),
                TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "ລາຄາ (Price)", suffixText: "LAK", filled: true, fillColor: paperWhite, border: OutlineInputBorder(borderSide: BorderSide.none))),
                const SizedBox(height: 10),
                TextField(controller: imageCtrl, decoration: const InputDecoration(labelText: "ລິ້ງຮູບພາບ (Image URL - Optional)", hintText: "ວາງລິ້ງຮູບໃສ່ທີ່ນີ້...", filled: true, fillColor: paperWhite, border: OutlineInputBorder(borderSide: BorderSide.none))),
                const SizedBox(height: 15),
                const Text("ໝວດໝູ່ (Category)", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  children: ["Coffee", "Tea", "Dessert", "Other"].map((c) => ChoiceChip(
                    label: Text(c), selected: newCategory == c, selectedColor: earthBrown, labelStyle: TextStyle(color: newCategory == c ? paperWhite : softBlack),
                    onSelected: (val) { if (val) setSheetState(() => newCategory = c); }
                  )).toList()
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: mossGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
                      Map<String, dynamic> newProduct = {
                        "id": isEditing ? existingProduct['id'] : DateTime.now().millisecondsSinceEpoch,
                        "name": nameCtrl.text,
                        "price": double.tryParse(priceCtrl.text) ?? 0,
                        "category": newCategory,
                        "stock": 999,
                        "image": imageCtrl.text
                      };
                      
                      setState(() { 
                        if (isEditing) { products[index!] = newProduct; } 
                        else { products.add(newProduct); }
                      });
                      
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('cached_products', json.encode(products));
                      
                      Navigator.pop(context);
                      if(isEditing) Navigator.pop(context); 
                      showSoftSnackbar(isEditing ? "✅ ອັບເດດເມນູສຳເລັດ!" : "🎉 ເພີ່ມເມນູໃໝ່ສຳເລັດ!");
                    },
                    child: const Text("ບັນທຶກ (Save)", style: TextStyle(color: paperWhite, fontSize: 18))
                  )
                ),
                const SizedBox(height: 20),
              ]
            )
          );
        });
      }
    );
  }

  void showManageOptions(int index, Map item) {
    showModalBottomSheet(
      context: context, backgroundColor: bgCream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(leading: const Icon(Icons.edit, color: mossGreen), title: const Text("ແກ້ໄຂເມນູນີ້ (Edit)"), onTap: () => showManageProductDialog(existingProduct: item, index: index)),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent), title: const Text("ລຶບເມນູນີ້ (Delete)"),
              onTap: () async {
                setState(() { products.removeAt(index); });
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('cached_products', json.encode(products));
                Navigator.pop(context);
                showSoftSnackbar("🗑️ ລຶບເມນູສຳເລັດ!");
              },
            ),
          ],
        ),
      )
    );
  }

  // 🌿 --- UI Helpers ---
  IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Coffee': return Icons.coffee;
      case 'Tea': return Icons.emoji_food_beverage;
      case 'Dessert': return Icons.cake;
      case 'Other': return Icons.local_drink;
      default: return Icons.fastfood;
    }
  }

  void showSoftSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: paperWhite, fontFamily: 'serif', fontSize: 16)),
      backgroundColor: softBlack, 
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 3),
    ));
  }

  void openProductOptionDialog(Map product) {
    bool isDessert = product['category'] == 'Dessert';
    String selectedType = "Iced";
    String selectedSweet = "100%";
    String selectedMilk = "Cow Milk"; 
    
    if (isDessert) { selectedType = "Normal"; selectedSweet = "-"; }
    TextEditingController noteController = TextEditingController();
    double basePrice = safeParse(product['price']);
    double finalPrice = basePrice;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: bgCream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            finalPrice = basePrice;
            if (!isDessert && selectedMilk == "Oat Milk") { finalPrice += 10000; }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(getCategoryIcon(product['category']), color: earthBrown, size: 28),
                      const SizedBox(width: 10),
                      Expanded(child: Text(product['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: softBlack))),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text("${NumberFormat("#,##0").format(finalPrice)} LAK", style: const TextStyle(fontSize: 18, color: earthBrown, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  if (!isDessert) ...[
                    const Text("ປະເພດ (Type)", style: TextStyle(color: softBlack, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10.0, 
                      children: ["Hot", "Iced"].map((type) { 
                        bool isSel = selectedType == type;
                        return ChoiceChip(label: Text(type, style: TextStyle(color: isSel ? paperWhite : softBlack, fontWeight: FontWeight.bold)), selected: isSel, showCheckmark: false, selectedColor: earthBrown, backgroundColor: paperWhite, side: BorderSide(color: isSel ? earthBrown : borderColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), onSelected: (selected) { if (selected) setSheetState(() => selectedType = type); }); 
                      }).toList()
                    ),
                    const SizedBox(height: 15),

                    if (product['category'] == 'Coffee' || product['category'] == 'Tea') ...[
                      const Text("ປະເພດນົມ (Milk)", style: TextStyle(color: softBlack, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10.0, 
                        children: ["Cow Milk", "Oat Milk"].map((milk) { 
                          bool isSel = selectedMilk == milk;
                          String label = milk == "Oat Milk" ? "ນົມໂອ໊ດ (Oat) +10k" : "ນົມງົວ (Cow)";
                          return ChoiceChip(label: Text(label, style: TextStyle(color: isSel ? paperWhite : softBlack, fontWeight: FontWeight.bold)), selected: isSel, showCheckmark: false, selectedColor: mossGreen, backgroundColor: paperWhite, side: BorderSide(color: isSel ? mossGreen : borderColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), onSelected: (selected) { if (selected) setSheetState(() => selectedMilk = milk); }); 
                        }).toList()
                      ),
                      const SizedBox(height: 15),
                    ],

                    const Text("ຄວາມຫວານ (Sweetness)", style: TextStyle(color: softBlack, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10.0, 
                      children: ["0%", "25%", "50%", "100%"].map((sweet) { 
                        bool isSel = selectedSweet == sweet;
                        return ChoiceChip(label: Text(sweet, style: TextStyle(color: isSel ? paperWhite : softBlack, fontWeight: FontWeight.bold)), selected: isSel, showCheckmark: false, selectedColor: earthBrown, backgroundColor: paperWhite, side: BorderSide(color: isSel ? earthBrown : borderColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), onSelected: (selected) { if (selected) setSheetState(() => selectedSweet = sweet); }); 
                      }).toList()
                    ),
                    const SizedBox(height: 20),
                  ],
                  TextField(controller: noteController, cursorColor: earthBrown, decoration: const InputDecoration(hintText: "ໝາຍເຫດ / Note (Optional)...", hintStyle: TextStyle(color: mutedText), filled: true, fillColor: paperWhite, border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(8))))),
                  const SizedBox(height: 30), 
                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: earthBrown, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0), 
                      onPressed: () { 
                        String finalType = isDessert ? selectedType : "$selectedType, ${selectedMilk.split(' ')[0]}"; 
                        addToCart(product, finalType, selectedSweet, noteController.text, finalPrice); 
                        Navigator.pop(context); 
                      }, 
                      icon: const Icon(Icons.add_shopping_cart, color: paperWhite),
                      label: const Text("ເພີ່ມລົງກະຕ່າ (Add)", style: TextStyle(color: paperWhite, fontSize: 18, letterSpacing: 1))
                    )
                  ),
                  const SizedBox(height: 30),
                ]
              ),
            );
          },
        );
      },
    );
  }

  void addToCart(var product, String type, String sweet, String note, double finalPrice) {
    setState(() {
      var existingIndex = cart.indexWhere((item) => item['id'] == product['id'] && item['type'] == type && item['sweet'] == sweet);
      if (existingIndex != -1) { cart[existingIndex]['qty']++; } 
      else { cart.add({"id": product['id'], "name": product['name'], "price": finalPrice, "qty": 1, "type": type, "sweet": sweet, "note": note, "category": product['category']}); }
    });
  }
  void decreaseQty(int index) { setState(() { if (cart[index]['qty'] > 1) { cart[index]['qty']--; } else { cart.removeAt(index); } }); }
  void increaseQty(int index) { setState(() { cart[index]['qty']++; }); }

  Future<void> holdBill() async {
    if (cart.isEmpty) return;
    TextEditingController nameController = TextEditingController();
    showModalBottomSheet(
      context: context, backgroundColor: bgCream, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("ພັກບິນ (Hold Order) ⏸️", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(controller: nameController, decoration: const InputDecoration(hintText: "ຊື່ລູກຄ້າ / โต๊ะ", filled: true, fillColor: paperWhite, border: OutlineInputBorder(borderSide: BorderSide.none))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700], elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () async {
                  String name = nameController.text.isEmpty ? "Order ${DateFormat('HH:mm').format(DateTime.now())}" : nameController.text;
                  final prefs = await SharedPreferences.getInstance();
                  List<String> heldBills = prefs.getStringList('held_bills') ?? [];
                  heldBills.add(json.encode({ "name": name, "time": DateTime.now().toString(), "items": cart }));
                  await prefs.setStringList('held_bills', heldBills);
                  setState(() { cart.clear(); }); 
                  Navigator.pop(context); 
                  Navigator.pop(context); 
                  showSoftSnackbar("ພັກບິນຮຽບຮ້ອຍ!");
                }, 
                child: const Text("ບັນທຶກ (Hold)", style: TextStyle(color: paperWhite, fontSize: 18))
              )
            ),
            const SizedBox(height: 30),
          ],
        )
      )
    );
  }

  void showPaymentDialog() {
    double total = cart.fold(0.0, (sum, item) => sum + (item['price'] * item['qty']));
    showModalBottomSheet(
      context: context, backgroundColor: bgCream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            const Text("ເລືອກວິທີຊຳລະເງິນ", style: TextStyle(fontSize: 18, color: softBlack, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("${NumberFormat("#,##0").format(total)} LAK", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: mossGreen)),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(child: SizedBox(height: 60, child: ElevatedButton.icon(icon: const Icon(Icons.money, color: paperWhite), style: ElevatedButton.styleFrom(backgroundColor: mossGreen, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: () => placeOrder("CASH"), label: const Text("ເງິນສົດ", style: TextStyle(fontSize: 18, color: paperWhite))))),
                const SizedBox(width: 15),
                Expanded(child: SizedBox(height: 60, child: ElevatedButton.icon(icon: const Icon(Icons.qr_code, color: paperWhite), style: ElevatedButton.styleFrom(backgroundColor: earthBrown, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: () => placeOrder("QR_ONEPAY"), label: const Text("ສະແກນ QR", style: TextStyle(fontSize: 18, color: paperWhite))))),
              ],
            ),
            const SizedBox(height: 30),
          ]
        ),
      )
    );
  }

  void showCartDialog() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: bgCream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void updateState(Function action) { setState(() { action(); }); setSheetState(() {}); if (cart.isEmpty) Navigator.pop(context); }
            double total = cart.fold(0.0, (sum, item) => sum + (item['price'] * item['qty']));

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.85, 
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("🛒 ລາຍການສັ່ງຊື້", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: softBlack)),
                        GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: mutedText, size: 28))
                      ],
                    )
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: cart.length, 
                      itemBuilder: (context, index) {
                        final item = cart[index]; 
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(color: paperWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start, 
                                  children: [
                                    Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    if (item['category'] != 'Dessert') Text("${item['type']} · Sweet ${item['sweet']}", style: const TextStyle(color: mossGreen, fontSize: 13, fontWeight: FontWeight.bold)),
                                    if (item['note'] != "") Text("Note: ${item['note']}", style: TextStyle(color: Colors.red[400], fontSize: 12, fontStyle: FontStyle.italic)),
                                    const SizedBox(height: 6),
                                    Text("${NumberFormat("#,##0").format(item['price'])} LAK", style: const TextStyle(color: softBlack)),
                                  ]
                                )
                              ),
                              Row(
                                children: [
                                  IconButton(icon: const Icon(Icons.remove_circle_outline, color: earthBrown), onPressed: () => updateState(() => decreaseQty(index))),
                                  Text("${item['qty']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  IconButton(icon: const Icon(Icons.add_circle_outline, color: mossGreen), onPressed: () => updateState(() => increaseQty(index))),
                                ]
                              )
                            ],
                          ),
                        );
                      }
                    )
                  ),
                  Container(
                    padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: paperWhite, border: Border(top: BorderSide(color: borderColor))), 
                    child: Column(
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("ລວມ:", style: TextStyle(fontSize: 18, color: softBlack, fontWeight: FontWeight.bold)), Text("${NumberFormat("#,##0").format(total)} LAK", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: mossGreen))]),
                        const SizedBox(height: 20), 
                        Row(
                          children: [
                            Expanded(flex: 1, child: SizedBox(height: 55, child: ElevatedButton(onPressed: cart.isEmpty ? null : holdBill, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[50], elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.orange.shade200))), child: Icon(Icons.pause, color: Colors.orange[800])))),
                            const SizedBox(width: 15),
                            Expanded(flex: 3, child: SizedBox(height: 55, child: ElevatedButton(onPressed: cart.isEmpty ? null : showPaymentDialog, style: ElevatedButton.styleFrom(backgroundColor: mossGreen, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text("ຊຳລະເງິນ (PAY)", style: TextStyle(fontSize: 18, color: paperWhite, fontWeight: FontWeight.bold))))),
                          ],
                        )
                      ]
                    )
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }

  // --- Views ---
  Future<void> showHeldBillsDialog() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> heldBills = prefs.getStringList('held_bills') ?? [];
    showModalBottomSheet(
      context: context, backgroundColor: bgCream, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  const Padding(padding: EdgeInsets.all(20), child: Align(alignment: Alignment.centerLeft, child: Text("📂 ບິນທີ່ພັກໄວ້ (Queue)", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)))),
                  Expanded(
                    child: heldBills.isEmpty 
                      ? const Center(child: Text("ບໍ່ມີລາຍການ", style: TextStyle(color: mutedText)))
                      : ListView.builder(
                          itemCount: heldBills.length,
                          itemBuilder: (context, index) {
                            Map<String, dynamic> bill = json.decode(heldBills[index]);
                            List items = bill['items'];
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(color: paperWhite, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor)),
                              child: ListTile(
                                leading: CircleAvatar(backgroundColor: Colors.orange[100], child: Icon(Icons.pause, color: Colors.orange[800])),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                                title: Text(bill['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), subtitle: Text("${items.length} ລາຍການ", style: const TextStyle(color: mutedText)),
                                trailing: TextButton(
                                  style: TextButton.styleFrom(foregroundColor: earthBrown, backgroundColor: bgCream),
                                  onPressed: () async {
                                    if (cart.isNotEmpty) { showSoftSnackbar("ກະລຸນາເຄຍກະຕ່າປັດຈຸບັນກ່ອນ"); return; }
                                    setState(() { cart = List<Map<String, dynamic>>.from(items); });
                                    heldBills.removeAt(index); await prefs.setStringList('held_bills', heldBills);
                                    Navigator.pop(context);
                                  }, 
                                  child: const Text("ເລືອກ (Resume)", style: TextStyle(fontWeight: FontWeight.bold))
                                ),
                              ),
                            );
                          },
                        ),
                  ),
                ],
              )
            );
          }
        );
      }
    );
  }

  // 📝 --- ระบบประวัติบิล (แตะเพื่อกางดูรายละเอียดด้านใน) + เลขลำดับคิว ---
  Future<void> showOrderHistory() async {
    final prefs = await SharedPreferences.getInstance();
    showModalBottomSheet(
      context: context, backgroundColor: bgCream, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setHistoryState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: FutureBuilder(
                future: http.get(Uri.parse('$serverUrl/orders')).timeout(const Duration(seconds: 3)),
                builder: (context, snapshot) {
                  List orders = [];
                  List<String> offlineOrdersStr = prefs.getStringList('offline_orders') ?? [];
                  List offlineOrders = offlineOrdersStr.map((str) => json.decode(str)).toList();

                  if (snapshot.hasData && snapshot.data!.statusCode == 200) {
                    String responseBody = utf8.decode(snapshot.data!.bodyBytes);
                    prefs.setString('cached_history', responseBody);
                    orders = json.decode(responseBody);
                  } else {
                    String? cachedHistory = prefs.getString('cached_history');
                    if (cachedHistory != null) orders = json.decode(cachedHistory);
                  }

                  orders.addAll(offlineOrders);
                  orders.sort((a, b) => (b['created_at'] ?? "").compareTo(a['created_at'] ?? ""));

                  return Column(
                    children: [
                      const Padding(padding: EdgeInsets.all(20), child: Align(alignment: Alignment.centerLeft, child: Text("🧾 ປະຫວັດການຂາຍ", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)))),
                      Expanded(
                        child: orders.isEmpty ? const Center(child: Text("ຍັງບໍ່ມີການຂາຍ", style: TextStyle(color: mutedText)))
                        : ListView.builder(
                            itemCount: orders.length, 
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              bool isOffline = order['id'].toString().startsWith("OFFLINE");
                              List items = order['items'] ?? []; 
                              int seqNum = orders.length - index; // สร้างเลขลำดับคิวจากจำนวนบิล

                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(color: paperWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: isOffline ? Colors.orange.shade300 : borderColor)),
                                
                                // 🌟 ExpansionTile กางดูรายละเอียด 🌟
                                child: ExpansionTile(
                                  shape: const Border(),
                                  
                                  // 🌟 เปลี่ยนวงกลมเป็น ป้ายคิวทรงเหลี่ยม 🌟
                                  leading: Container(
                                    width: 55, height: 55,
                                    decoration: BoxDecoration(
                                      color: isOffline ? Colors.orange[50] : bgCream,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: isOffline ? Colors.orange.shade300 : borderColor)
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(isOffline ? "Offline" : "ບິນທີ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isOffline ? Colors.orange[800] : mutedText)),
                                        Text(isOffline ? "Q$seqNum" : "${order['id']}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isOffline ? Colors.orange[900] : earthBrown)),
                                      ]
                                    )
                                  ),

                                  title: Text("${NumberFormat("#,##0").format(safeParse(order['total_amount']))} LAK", style: const TextStyle(fontWeight: FontWeight.bold, color: mossGreen)), 
                                  subtitle: Text("${order['created_at']?.substring(11, 16) ?? ''} · ${order['payment_method']} ${isOffline ? '(ຍັງບໍ່ຊິງຄ໌)' : ''}", style: const TextStyle(color: mutedText)), 
                                  
                                  // รายละเอียดที่ซ่อนอยู่ด้านใน
                                  children: [
                                    const Divider(color: borderColor, height: 1),
                                    ...items.map((item) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("${item['quantity']}x", style: const TextStyle(fontWeight: FontWeight.bold, color: earthBrown, fontSize: 16)),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(item['product_name'] ?? 'Unknown Item', style: const TextStyle(fontWeight: FontWeight.bold, color: softBlack, fontSize: 16)),
                                                  if (item['item_type'] != null && item['item_type'].toString().isNotEmpty)
                                                    Text("${item['item_type']} · Sweet ${item['sweetness']}", style: const TextStyle(color: mutedText, fontSize: 13)),
                                                  if (item['note'] != null && item['note'].toString().isNotEmpty)
                                                    Text("Note: ${item['note']}", style: TextStyle(color: Colors.red[400], fontSize: 13, fontStyle: FontStyle.italic)),
                                                ],
                                              )
                                            ),
                                            Text("${NumberFormat("#,##0").format(safeParse(item['price_at_sale']) * safeParse(item['quantity']))} LAK", style: const TextStyle(color: softBlack)),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    
                                    // ปุ่ม Refund ซ่อนไว้ในบิล
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          icon: const Icon(Icons.undo, color: Colors.redAccent, size: 18),
                                          label: const Text("ຍົກເລີກບິນ (Refund)", style: TextStyle(color: Colors.redAccent)),
                                          onPressed: () {
                                            showDialog(
                                              context: context, 
                                              builder: (_) => AlertDialog(
                                                backgroundColor: bgCream, title: const Text("⚠️ ຍົກເລີກບິນ?"), content: const Text("ຍົກເລີກບິນແລ້ວຄືນສິນຄ້າເຂົ້າ Stock ແມ່ນບໍ່?"),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("ບໍ່ (Cancel)", style: TextStyle(color: mutedText))),
                                                  ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () { Navigator.pop(context); Navigator.pop(context); processRefund(order['id']); }, child: const Text("ຢືນຢັນ (Refund)", style: TextStyle(color: paperWhite)))
                                                ]
                                              )
                                            );
                                          },
                                        ),
                                      ),
                                    )
                                  ],
                                )
                              );
                            }
                          )
                      ),
                    ],
                  );
                }
              )
            );
          }
        );
      }
    );
  }

  List getFilteredProducts() { if (selectedCategory == "All") return products; return products.where((i) => i['category'] == selectedCategory).toList(); }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat("#,##0");
    double totalCartPrice = cart.fold(0.0, (sum, item) => sum + (item['price'] * item['qty']));
    int totalItems = cart.fold(0, (sum, item) => sum + (item['qty'] as int));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sumday ☕"), 
        actions: [
          IconButton(onPressed: showHeldBillsDialog, icon: const Icon(Icons.access_time)), 
          IconButton(onPressed: showOrderHistory, icon: const Icon(Icons.receipt_long)), 
          IconButton(onPressed: showAddProductDialog, icon: const Icon(Icons.add_box_outlined, color: mossGreen)), 
          const SizedBox(width: 10),
        ]
      ),
      body: RefreshIndicator(
        onRefresh: fetchProducts,
        color: earthBrown,
        backgroundColor: paperWhite,
        child: Column(
          children: [
            Container(
              height: 60, padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10), 
              child: ListView(
                scrollDirection: Axis.horizontal, 
                children: categories.map((c) {
                  bool isSelected = selectedCategory == c;
                  return Padding(padding: const EdgeInsets.only(right: 10), child: ElevatedButton(onPressed: () => setState(() => selectedCategory = c), style: ElevatedButton.styleFrom(elevation: 0, backgroundColor: isSelected ? earthBrown : paperWhite, foregroundColor: isSelected ? paperWhite : softBlack, side: BorderSide(color: isSelected ? earthBrown : borderColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 20)), child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold))));
                }).toList()
              )
            ),
            
            Expanded(
              child: selectedCategory == "About CEO" 
              ? Center(
                  child: SingleChildScrollView( 
                    physics: const AlwaysScrollableScrollPhysics(), 
                    child: Container(
                      width: 300, padding: const EdgeInsets.all(30), decoration: BoxDecoration(color: paperWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, 
                        children: [
                          ClipRRect(borderRadius: BorderRadius.circular(100), child: Image.asset("assets/sumday.jpg", fit: BoxFit.cover, height: 120, width: 120)),
                          const SizedBox(height: 20), 
                          const Text("MR. MICK", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: softBlack, letterSpacing: 1)), 
                          const Text("Founder & CEO", style: TextStyle(fontSize: 14, color: mutedText, fontStyle: FontStyle.italic)), 
                          const SizedBox(height: 15), 
                          Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5), decoration: BoxDecoration(color: mossGreen, borderRadius: BorderRadius.circular(20)), child: const Text("Priceless 💎", style: TextStyle(fontSize: 14, color: paperWhite, fontWeight: FontWeight.bold))), 
                        ]
                      )
                    ),
                  )
                )
              : isLoading 
                ? const Center(child: CircularProgressIndicator(color: earthBrown)) 
                : GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(), 
                    padding: const EdgeInsets.all(15), 
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.85, crossAxisSpacing: 15, mainAxisSpacing: 15), 
                    itemCount: getFilteredProducts().length, 
                    itemBuilder: (context, index) {
                      final item = getFilteredProducts()[index];
                      int stock = item['stock'] ?? 0; bool isOutOfStock = stock <= 0;
                      
                      return GestureDetector(
                        onTap: isOutOfStock ? null : () => openProductOptionDialog(item), 
                        onLongPress: () => showManageOptions(index, item), 
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: isOutOfStock ? bgCream : paperWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center, 
                            children: [ 
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(color: bgCream, borderRadius: BorderRadius.circular(8)),
                                  child: (item['image'] != null && item['image'].toString().isNotEmpty)
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        item['image'], 
                                        width: double.infinity, 
                                        height: double.infinity, 
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Center(child: Icon(getCategoryIcon(item['category']), size: 45, color: isOutOfStock ? mutedText : earthBrown)),
                                      ),
                                    )
                                  : Center(child: Icon(getCategoryIcon(item['category']), size: 45, color: isOutOfStock ? mutedText : earthBrown))
                                )
                              ), 
                              const SizedBox(height: 12), 
                              Text(item['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isOutOfStock ? mutedText : softBlack), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis), 
                              const SizedBox(height: 4), 
                              Text("${fmt.format(safeParse(item['price']))} ກີບ", style: TextStyle(fontSize: 14, color: isOutOfStock ? mutedText : mossGreen, fontWeight: FontWeight.bold)), 
                            ]
                          )
                        )
                      );
                    }
                  )
            )
          ],
        ),
      ),

      bottomNavigationBar: cart.isEmpty ? null : BottomAppBar(
        color: paperWhite, elevation: 10,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("ກະຕ່າ (${totalItems} ລາຍການ)", style: const TextStyle(fontSize: 14, color: mutedText, fontWeight: FontWeight.bold)),
                  Text("${fmt.format(totalCartPrice)} LAK", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: softBlack)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: showCartDialog, 
                icon: const Icon(Icons.shopping_cart, color: paperWhite), label: const Text("ຈ່າຍເງິນ (View)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(backgroundColor: earthBrown, foregroundColor: paperWhite, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              )
            ],
          ),
        ),
      ),
    );
  }
}