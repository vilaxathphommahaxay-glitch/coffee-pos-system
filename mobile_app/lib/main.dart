import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

void main() { 
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CoffeeShopApp()); 
}

// 🎨 --- Color Palette ---
const Color bgCream = Color(0xFFF9F6F0);
const Color earthBrown = Color(0xFF5D4037);
const Color mossGreen = Color(0xFF6B705C);
const Color softBlack = Color(0xFF2C2C2C);
const Color paperWhite = Color(0xFFFFFFFF);
const Color borderColor = Color(0xFFE8E4D9);
const Color mutedText = Color(0xFF8D8D8D);

const Color bgBaseDark = Color(0xFF1A1817);
const Color surfaceDark = Color(0xFF242220); 
const Color earthBrownDark = Color(0xFFD4B895); 
const Color mossGreenDark = Color(0xFF8BA372); 
const Color softBlackDark = Color(0xFFF9F6F0);
const Color borderColorDark = Color(0xFF383431); 
const Color mutedTextDark = Color(0xFF8A847D);

// 📦 --- Models ---
class ProductModel {
  final dynamic id;
  final String name;
  final double price;
  final String category;
  final int stock;
  final String image;

  ProductModel({required this.id, required this.name, required this.price, required this.category, required this.stock, required this.image});

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'].toString(),
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      category: json['category'].toString(),
      stock: int.tryParse(json['stock'].toString()) ?? 0,
      image: json['image']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'price': price, 'category': category, 'stock': stock, 'image': image
  };
}

class CartItem {
  final dynamic productId;
  final String name;
  final double price;
  int qty;
  final String type;
  final String sweet;
  final String note;
  final String category;

  CartItem({required this.productId, required this.name, required this.price, required this.qty, required this.type, required this.sweet, required this.note, required this.category});

  Map<String, dynamic> toJson() => {
    "product_id": productId, "product_name": name, "quantity": qty, "price_at_sale": price,
    "sweetness": sweet, "item_type": type, "note": note, "category": category
  };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['product_id'], name: json['product_name'], price: (json['price_at_sale'] as num).toDouble(),
      qty: json['quantity'], type: json['item_type'], sweet: json['sweetness'], note: json['note'], category: json['category'] ?? ''
    );
  }
}

// 🗄️ --- SQLite Database Helper ---
class OfflineDBHelper {
  static final OfflineDBHelper instance = OfflineDBHelper._init();
  static Database? _database;
  OfflineDBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pos_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final fullPath = path.join(dbPath, filePath); 
    return await openDatabase(fullPath, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE offline_orders (
        id TEXT PRIMARY KEY, payload TEXT NOT NULL, created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> insertOrder(String id, Map<String, dynamic> payload) async {
    final db = await instance.database;
    await db.insert('offline_orders', {
      'id': id, 'payload': json.encode(payload), 'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedOrders() async {
    final db = await instance.database;
    return await db.query('offline_orders', orderBy: 'created_at ASC');
  }

  Future<void> deleteOrder(String id) async {
    final db = await instance.database;
    await db.delete('offline_orders', where: 'id = ?', whereArgs: [id]);
  }
}

class CoffeeShopApp extends StatefulWidget {
  const CoffeeShopApp({super.key});
  @override
  State<CoffeeShopApp> createState() => _CoffeeShopAppState();
}

class _CoffeeShopAppState extends State<CoffeeShopApp> {
  bool isDarkMode = false;
  void toggleTheme() { setState(() { isDarkMode = !isDarkMode; }); }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sumday POS',
      debugShowCheckedModeBanner: false,
      theme: isDarkMode ? _buildDarkTheme() : _buildLightTheme(),
      home: PosScreen(isDarkMode: isDarkMode, toggleTheme: toggleTheme),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light, scaffoldBackgroundColor: bgCream, fontFamily: 'serif',
      appBarTheme: const AppBarTheme(backgroundColor: bgCream, elevation: 0, scrolledUnderElevation: 0, iconTheme: IconThemeData(color: softBlack), titleTextStyle: TextStyle(color: softBlack, fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      colorScheme: const ColorScheme.light(primary: earthBrown, secondary: mossGreen, surface: paperWhite, onSurface: softBlack, outline: borderColor, onSurfaceVariant: mutedText),
      useMaterial3: true,
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark, scaffoldBackgroundColor: bgBaseDark, fontFamily: 'serif',
      appBarTheme: const AppBarTheme(backgroundColor: bgBaseDark, elevation: 0, scrolledUnderElevation: 0, iconTheme: IconThemeData(color: softBlackDark), titleTextStyle: TextStyle(color: softBlackDark, fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      colorScheme: const ColorScheme.dark(primary: earthBrownDark, secondary: mossGreenDark, surface: surfaceDark, onSurface: softBlackDark, outline: borderColorDark, onSurfaceVariant: mutedTextDark),
      useMaterial3: true,
    );
  }
}

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
  String selectedCategory = "All";
  final List<String> categories = ["All", "Coffee", "Tea", "Dessert", "Other", "About CEO"];
  
  // ควรย้ายไป .env
  final String serverUrl = "http://192.168.1.50:8000/api";

  @override
  void initState() {
    super.initState();
    fetchProducts();
    syncOfflineOrders();
  }

  Future<void> saveOrderOffline(Map<String, dynamic> orderData) async {
    String offlineId = "OFFLINE_${DateTime.now().millisecondsSinceEpoch}";
    orderData['id'] = offlineId; 
    orderData['created_at'] = DateTime.now().toIso8601String();
    await OfflineDBHelper.instance.insertOrder(offlineId, orderData);
  }

  Future<void> syncOfflineOrders() async {
    List<Map<String, dynamic>> unsyncedOrders = await OfflineDBHelper.instance.getUnsyncedOrders();
    if (unsyncedOrders.isEmpty) return;

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
  }

  Future<void> fetchProducts() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance(); 
    String? cachedData = prefs.getString('cached_products');
    
    if (cachedData != null && cachedData.isNotEmpty) {
      List decoded = json.decode(cachedData);
      products = decoded.map((p) => ProductModel.fromJson(p)).toList();
    }

    try {
      syncOfflineOrders(); 
      var response = await http.get(Uri.parse('$serverUrl/products')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        String responseBody = utf8.decode(response.bodyBytes);
        List decoded = json.decode(responseBody);
        setState(() { 
          products = decoded.map((p) => ProductModel.fromJson(p)).toList(); 
          isLoading = false; 
        });
        await prefs.setString('cached_products', responseBody); 
      } else { 
        throw Exception("Server Error");
      }
    } catch (e) { 
      setState(() => isLoading = false);
      if (products.isEmpty) {
        showSoftSnackbar("⚠️ ບໍ່ສາມາດໂຫຼດຂໍ້ມູນໄດ້ ກະລຸນາກວດສອບອິນເຕີເນັດ");
      } else {
        showSoftSnackbar("📡 ໃຊ້ງານໂໝດອອຟລາຍ (Offline Mode)");
      }
    }
  }

  Future<void> placeOrder(String paymentMethod) async {
    if (cart.isEmpty) return;
    Navigator.pop(context); 
    Navigator.pop(context);

    var orderData = { 
      "total_amount": cart.fold(0.0, (sum, item) => sum + (item.price * item.qty)), 
      "payment_method": paymentMethod, 
      "employee_id": 1, 
      "items": cart.map((i) => i.toJson()).toList() 
    };

    setState(() { cart.clear(); });
    showSoftSnackbar("✅ ຊຳລະເງິນສຳເລັດ! ($paymentMethod)");

    await saveOrderOffline(orderData);
    syncOfflineOrders();
  }

  Future<void> processRefund(dynamic orderId) async {
    if (orderId.toString().startsWith("OFFLINE_")) {
      await OfflineDBHelper.instance.deleteOrder(orderId.toString());
      showSoftSnackbar("✅ ຍົກເລີກບິນອອຟລາຍສຳເລັດ");
      return;
    }
    try {
      var response = await http.delete(Uri.parse('$serverUrl/orders/$orderId')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) { 
        showSoftSnackbar("✅ ຍົກເລີກບິນ ແລະ ຄືນສະຕ໋ອກແລ້ວ"); 
        fetchProducts(); 
      } else { 
        showSoftSnackbar("ບໍ່ສາມາດຍົກເລີກໄດ້ໃນຂະນະນີ້");
      }
    } catch (e) { 
      showSoftSnackbar("⚠️ ບໍ່ມີອິນເຕີເນັດ ບໍ່ສາມາດຍົກເລີກບິນເກົ່າໄດ້"); 
    }
  }

  void showAddProductDialog() { showManageProductDialog(); }

  void showManageProductDialog({ProductModel? existingProduct, int? index}) {
    bool isEditing = existingProduct != null;
    TextEditingController nameCtrl = TextEditingController(text: isEditing ? existingProduct.name : "");
    TextEditingController priceCtrl = TextEditingController(text: isEditing ? existingProduct.price.toString() : "");
    TextEditingController imageCtrl = TextEditingController(text: isEditing ? existingProduct.image : "");
    String newCategory = isEditing ? existingProduct.category : "Coffee";
    
    showModalBottomSheet(
      context: context, backgroundColor: Theme.of(context).scaffoldBackgroundColor, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return StatefulBuilder(builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isEditing ? "✏️ ແກ້ໄຂເມນູ" : "➕ ເພີ່ມເມນູໃໝ່", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                    if (isEditing) 
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () async {
                          setState(() { products.removeAt(index!); });
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('cached_products', json.encode(products.map((p) => p.toJson()).toList()));
                          Navigator.pop(context); Navigator.pop(context); 
                          showSoftSnackbar("🗑️ ລຶບເມນູສຳເລັດ!");
                        }
                      )
                  ],
                ),
                const SizedBox(height: 15),
                TextField(controller: nameCtrl, style: TextStyle(color: colorScheme.onSurface), decoration: InputDecoration(labelText: "ຊື່ເມນູ (Name)", labelStyle: TextStyle(color: colorScheme.onSurfaceVariant), filled: true, fillColor: colorScheme.surface, border: const OutlineInputBorder(borderSide: BorderSide.none))),
                const SizedBox(height: 10),
                TextField(controller: priceCtrl, style: TextStyle(color: colorScheme.onSurface), keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "ລາຄາ (Price)", suffixText: "LAK", labelStyle: TextStyle(color: colorScheme.onSurfaceVariant), filled: true, fillColor: colorScheme.surface, border: const OutlineInputBorder(borderSide: BorderSide.none))),
                const SizedBox(height: 10),
                TextField(controller: imageCtrl, style: TextStyle(color: colorScheme.onSurface), decoration: InputDecoration(labelText: "ລິ້ງຮູບພາບ (URL)", hintText: "ວາງລິ້ງຮູບ...", labelStyle: TextStyle(color: colorScheme.onSurfaceVariant), filled: true, fillColor: colorScheme.surface, border: const OutlineInputBorder(borderSide: BorderSide.none))),
                const SizedBox(height: 15),
                Text("ໝວດໝູ່ (Category)", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  children: ["Coffee", "Tea", "Dessert", "Other"].map((c) => ChoiceChip(
                    label: Text(c), selected: newCategory == c, selectedColor: colorScheme.primary, backgroundColor: colorScheme.surface,
                    side: BorderSide(color: newCategory == c ? colorScheme.primary : colorScheme.outline),
                    labelStyle: TextStyle(color: newCategory == c ? (widget.isDarkMode ? softBlackDark : paperWhite) : colorScheme.onSurface),
                    showCheckmark: false,
                    onSelected: (val) { if (val) setSheetState(() => newCategory = c); }
                  )).toList()
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: colorScheme.secondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
                      ProductModel newProduct = ProductModel(
                        id: isEditing ? existingProduct.id : DateTime.now().millisecondsSinceEpoch,
                        name: nameCtrl.text, price: double.tryParse(priceCtrl.text) ?? 0,
                        category: newCategory, stock: 999, image: imageCtrl.text
                      );
                      setState(() { if (isEditing) { products[index!] = newProduct; } else { products.add(newProduct); } });
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('cached_products', json.encode(products.map((p) => p.toJson()).toList()));
                      Navigator.pop(context); if(isEditing) Navigator.pop(context); 
                      showSoftSnackbar(isEditing ? "✅ ອັບເດດເມນູສຳເລັດ!" : "🎉 ເພີ່ມເມນູໃໝ່ສຳເລັດ!");
                    },
                    child: Text("ບັນທຶກ (Save)", style: TextStyle(color: widget.isDarkMode ? softBlackDark : paperWhite, fontSize: 18))
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

  void showManageOptions(int index, ProductModel item) {
    showModalBottomSheet(
      context: context, backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
              const SizedBox(height: 20),
              ListTile(leading: Icon(Icons.edit, color: colorScheme.secondary), title: Text("ແກ້ໄຂເມນູນີ້ (Edit)", style: TextStyle(color: colorScheme.onSurface)), onTap: () => showManageProductDialog(existingProduct: item, index: index)),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent), title: const Text("ລຶບເມນູນີ້ (Delete)", style: TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  setState(() { products.removeAt(index); });
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('cached_products', json.encode(products.map((p) => p.toJson()).toList()));
                  Navigator.pop(context); showSoftSnackbar("🗑️ ລຶບເມນູສຳເລັດ!");
                },
              ),
            ],
          ),
        );
      }
    );
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

  void showSoftSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: TextStyle(color: Theme.of(context).scaffoldBackgroundColor, fontFamily: 'serif', fontSize: 16)),
      backgroundColor: Theme.of(context).colorScheme.onSurface, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), duration: const Duration(seconds: 3),
    ));
  }

  void openProductOptionDialog(ProductModel product) {
    bool isDessert = product.category == 'Dessert';
    String selectedType = "Iced";
    String selectedSweet = "100%";
    String selectedMilk = "Cow Milk"; 
    if (isDessert) { selectedType = "Normal"; selectedSweet = "-"; }
    TextEditingController noteController = TextEditingController();
    double basePrice = product.price;
    double finalPrice = basePrice;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
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
                      Icon(getCategoryIcon(product.category), color: colorScheme.primary, size: 28), const SizedBox(width: 10),
                      Expanded(child: Text(product.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.onSurface))),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text("${NumberFormat("#,##0").format(finalPrice)} LAK", style: TextStyle(fontSize: 18, color: colorScheme.primary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  if (!isDessert) ...[
                    Text("ປະເພດ (Type)", style: TextStyle(color: colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
                    Wrap(
                      spacing: 10.0, 
                      children: ["Hot", "Iced"].map((type) { 
                        bool isSel = selectedType == type;
                        return ChoiceChip(label: Text(type, style: TextStyle(color: isSel ? (widget.isDarkMode ? softBlackDark : paperWhite) : colorScheme.onSurface, fontWeight: FontWeight.bold)), selected: isSel, showCheckmark: false, selectedColor: colorScheme.primary, backgroundColor: colorScheme.surface, side: BorderSide(color: isSel ? colorScheme.primary : colorScheme.outline), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), onSelected: (selected) { if (selected) setSheetState(() => selectedType = type); });
                      }).toList()
                    ),
                    const SizedBox(height: 15),

                    if (product.category == 'Coffee' || product.category == 'Tea') ...[
                      Text("ປະເພດນົມ (Milk)", style: TextStyle(color: colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
                      Wrap(
                        spacing: 10.0, 
                        children: ["Cow Milk", "Oat Milk"].map((milk) { 
                          bool isSel = selectedMilk == milk;
                          String label = milk == "Oat Milk" ? "ນົມໂອ໊ດ (Oat) +10k" : "ນົມງົວ (Cow)";
                          return ChoiceChip(label: Text(label, style: TextStyle(color: isSel ? (widget.isDarkMode ? softBlackDark : paperWhite) : colorScheme.onSurface, fontWeight: FontWeight.bold)), selected: isSel, showCheckmark: false, selectedColor: colorScheme.secondary, backgroundColor: colorScheme.surface, side: BorderSide(color: isSel ? colorScheme.secondary : colorScheme.outline), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), onSelected: (selected) { if (selected) setSheetState(() => selectedMilk = milk); });
                        }).toList()
                      ),
                      const SizedBox(height: 15),
                    ],

                    Text("ຄວາມຫວານ (Sweetness)", style: TextStyle(color: colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
                    Wrap(
                      spacing: 10.0, 
                      children: ["0%", "25%", "50%", "100%"].map((sweet) { 
                        bool isSel = selectedSweet == sweet;
                        return ChoiceChip(label: Text(sweet, style: TextStyle(color: isSel ? (widget.isDarkMode ? softBlackDark : paperWhite) : colorScheme.onSurface, fontWeight: FontWeight.bold)), selected: isSel, showCheckmark: false, selectedColor: colorScheme.primary, backgroundColor: colorScheme.surface, side: BorderSide(color: isSel ? colorScheme.primary : colorScheme.outline), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), onSelected: (selected) { if (selected) setSheetState(() => selectedSweet = sweet); }); 
                      }).toList()
                    ),
                    const SizedBox(height: 20),
                  ],
                  TextField(controller: noteController, style: TextStyle(color: colorScheme.onSurface), cursorColor: colorScheme.primary, decoration: InputDecoration(hintText: "ໝາຍເຫດ / Note (Optional)...", hintStyle: TextStyle(color: colorScheme.onSurfaceVariant), filled: true, fillColor: colorScheme.surface, border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(8))))),
                  const SizedBox(height: 30), 
                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0), 
                      onPressed: () { 
                        String finalType = isDessert ? selectedType : "$selectedType, ${selectedMilk.split(' ')[0]}";
                        addToCart(product, finalType, selectedSweet, noteController.text, finalPrice); 
                        Navigator.pop(context); 
                      }, 
                      icon: Icon(Icons.add_shopping_cart, color: widget.isDarkMode ? softBlackDark : paperWhite),
                      label: Text("ເພີ່ມລົງກະຕ່າ (Add)", style: TextStyle(color: widget.isDarkMode ? softBlackDark : paperWhite, fontSize: 18, letterSpacing: 1))
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

  void addToCart(ProductModel product, String type, String sweet, String note, double finalPrice) {
    setState(() {
      var existingIndex = cart.indexWhere((item) => item.productId == product.id && item.type == type && item.sweet == sweet);
      if (existingIndex != -1) { cart[existingIndex].qty++; } 
      else { cart.add(CartItem(productId: product.id, name: product.name, price: finalPrice, qty: 1, type: type, sweet: sweet, note: note, category: product.category)); }
    });
  }
  void decreaseQty(int index) { setState(() { if (cart[index].qty > 1) { cart[index].qty--; } else { cart.removeAt(index); } }); }
  void increaseQty(int index) { setState(() { cart[index].qty++; }); }

  Future<void> holdBill() async {
    if (cart.isEmpty) return;
    TextEditingController nameController = TextEditingController();
    showModalBottomSheet(
      context: context, backgroundColor: Theme.of(context).scaffoldBackgroundColor, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("ພັກບິນ (Hold Order) ⏸️", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.onSurface)), const SizedBox(height: 15),
              TextField(controller: nameController, style: TextStyle(color: colorScheme.onSurface), decoration: InputDecoration(hintText: "ຊື່ລູກຄ້າ / โต๊ะ", hintStyle: TextStyle(color: colorScheme.onSurfaceVariant), filled: true, fillColor: colorScheme.surface, border: const OutlineInputBorder(borderSide: BorderSide.none))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700], elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () async {
                    String name = nameController.text.isEmpty ? "Order ${DateFormat('HH:mm').format(DateTime.now())}" : nameController.text;
                    final prefs = await SharedPreferences.getInstance();
                    List<String> heldBills = prefs.getStringList('held_bills') ?? [];
                    heldBills.add(json.encode({ "name": name, "time": DateTime.now().toString(), "items": cart.map((e)=>e.toJson()).toList() }));
                    await prefs.setStringList('held_bills', heldBills);
                    setState(() { cart.clear(); }); 
                    Navigator.pop(context); Navigator.pop(context); 
                    showSoftSnackbar("ພັກບິນຮຽບຮ້ອຍ!");
                  }, 
                  child: const Text("ບັນທຶກ (Hold)", style: TextStyle(color: Colors.white, fontSize: 18))
                )
              ),
              const SizedBox(height: 30),
            ],
          )
        );
      }
    );
  }

  void showPaymentDialog() {
    double total = cart.fold(0.0, (sum, item) => sum + (item.price * item.qty));
    showModalBottomSheet(
      context: context, backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            children: [
              Text("ເລືອກວິທີຊຳລະເງິນ", style: TextStyle(fontSize: 18, color: colorScheme.onSurface, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
              Text("${NumberFormat("#,##0").format(total)} LAK", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: colorScheme.secondary)), const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(child: SizedBox(height: 60, child: ElevatedButton.icon(icon: Icon(Icons.money, color: widget.isDarkMode ? softBlackDark : paperWhite), style: ElevatedButton.styleFrom(backgroundColor: colorScheme.secondary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: () => placeOrder("CASH"), label: Text("ເງິນສົດ", style: TextStyle(fontSize: 18, color: widget.isDarkMode ? softBlackDark : paperWhite))))),
                  const SizedBox(width: 15),
                  Expanded(child: SizedBox(height: 60, child: ElevatedButton.icon(icon: Icon(Icons.qr_code, color: widget.isDarkMode ? softBlackDark : paperWhite), style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: () => placeOrder("QR_ONEPAY"), label: Text("ສະແກນ QR", style: TextStyle(fontSize: 18, color: widget.isDarkMode ? softBlackDark : paperWhite))))),
                ],
              ),
              const SizedBox(height: 30),
            ]
          ),
        );
      }
    );
  }

  void showCartDialog() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void updateState(Function action) { setState(() { action(); }); setSheetState(() {}); if (cart.isEmpty) Navigator.pop(context); }
            double total = cart.fold(0.0, (sum, item) => sum + (item.price * item.qty));

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.85, 
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("🛒 ລາຍການສັ່ງຊື້", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                        GestureDetector(onTap: () => Navigator.pop(context), child: Icon(Icons.close, color: colorScheme.onSurfaceVariant, size: 28))
                      ],
                    )
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: cart.length, 
                      itemBuilder: (context, index) {
                        final item = cart[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: colorScheme.outline)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start, 
                                  children: [
                                    Text(item.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface)), const SizedBox(height: 4),
                                    if (item.category != 'Dessert') Text("${item.type} · Sweet ${item.sweet}", style: TextStyle(color: colorScheme.secondary, fontSize: 13, fontWeight: FontWeight.bold)),
                                    if (item.note != "") Text("Note: ${item.note}", style: TextStyle(color: Colors.red[400], fontSize: 12, fontStyle: FontStyle.italic)),
                                    const SizedBox(height: 6),
                                    Text("${NumberFormat("#,##0").format(item.price)} LAK", style: TextStyle(color: colorScheme.onSurface)),
                                  ]
                                )
                              ),
                              Row(
                                children: [
                                  IconButton(icon: Icon(Icons.remove_circle_outline, color: colorScheme.primary), onPressed: () => updateState(() => decreaseQty(index))),
                                  Text("${item.qty}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                  IconButton(icon: Icon(Icons.add_circle_outline, color: colorScheme.secondary), onPressed: () => updateState(() => increaseQty(index))),
                                ]
                              )
                            ],
                          ),
                        );
                      }
                    )
                  ),
                  Container(
                    padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: colorScheme.surface, border: Border(top: BorderSide(color: colorScheme.outline))), 
                    child: Column(
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("ລວມ:", style: TextStyle(fontSize: 18, color: colorScheme.onSurface, fontWeight: FontWeight.bold)), Text("${NumberFormat("#,##0").format(total)} LAK", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.secondary))]),
                        const SizedBox(height: 20), 
                        Row(
                          children: [
                            Expanded(flex: 1, child: SizedBox(height: 55, child: ElevatedButton(onPressed: cart.isEmpty ? null : holdBill, style: ElevatedButton.styleFrom(backgroundColor: widget.isDarkMode ? Colors.orange.shade900 : Colors.orange[50], elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.orange.shade200))), child: Icon(Icons.pause, color: widget.isDarkMode ? Colors.white : Colors.orange[800])))),
                            const SizedBox(width: 15),
                            Expanded(flex: 3, child: SizedBox(height: 55, child: ElevatedButton(onPressed: cart.isEmpty ? null : showPaymentDialog, style: ElevatedButton.styleFrom(backgroundColor: colorScheme.secondary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: Text("ຊຳລະເງິນ (PAY)", style: TextStyle(fontSize: 18, color: widget.isDarkMode ? softBlackDark : paperWhite, fontWeight: FontWeight.bold))))),
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

  Future<void> showHeldBillsDialog() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> heldBills = prefs.getStringList('held_bills') ?? [];
    showModalBottomSheet(
      context: context, backgroundColor: Theme.of(context).scaffoldBackgroundColor, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  Padding(padding: const EdgeInsets.all(20), child: Align(alignment: Alignment.centerLeft, child: Text("📂 ບິນທີ່ພັກໄວ້ (Queue)", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.onSurface)))),
                  Expanded(
                    child: heldBills.isEmpty 
                      ? Center(child: Text("ບໍ່ມີລາຍການ", style: TextStyle(color: colorScheme.onSurfaceVariant)))
                      : ListView.builder(
                          itemCount: heldBills.length,
                          itemBuilder: (context, index) {
                            Map<String, dynamic> bill = json.decode(heldBills[index]);
                            List items = bill['items'];
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: colorScheme.outline)),
                              child: ListTile(
                                leading: CircleAvatar(backgroundColor: widget.isDarkMode ? Colors.orange.shade900 : Colors.orange[100], child: Icon(Icons.pause, color: widget.isDarkMode ? Colors.white : Colors.orange[800])),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                                title: Text(bill['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface)), subtitle: Text("${items.length} ລາຍການ", style: TextStyle(color: colorScheme.onSurfaceVariant)),
                                trailing: TextButton(
                                  style: TextButton.styleFrom(foregroundColor: colorScheme.primary, backgroundColor: Theme.of(context).scaffoldBackgroundColor),
                                  onPressed: () async {
                                    if (cart.isNotEmpty) { showSoftSnackbar("ກະລຸນາເຄຍກະຕ່າປັດຈຸບັນກ່ອນ"); return; }
                                    setState(() { cart = items.map((i) => CartItem.fromJson(i)).toList(); });
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

  Future<void> showOrderHistory() async {
    final prefs = await SharedPreferences.getInstance();
    showModalBottomSheet(
      context: context, backgroundColor: Theme.of(context).scaffoldBackgroundColor, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setHistoryState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: FutureBuilder(
                future: http.get(Uri.parse('$serverUrl/orders')).timeout(const Duration(seconds: 3)),
                builder: (context, snapshot) {
                  List orders = [];
                  if (snapshot.hasData && snapshot.data!.statusCode == 200) {
                    String responseBody = utf8.decode(snapshot.data!.bodyBytes);
                    prefs.setString('cached_history', responseBody);
                    orders = json.decode(responseBody);
                  } else {
                    String? cachedHistory = prefs.getString('cached_history');
                    if (cachedHistory != null) orders = json.decode(cachedHistory);
                  }

                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: OfflineDBHelper.instance.getUnsyncedOrders(),
                    builder: (context, offlineSnapshot) {
                      List offlineOrders = [];
                      if (offlineSnapshot.hasData) {
                        offlineOrders = offlineSnapshot.data!.map((row) {
                          var p = json.decode(row['payload']);
                          p['id'] = row['id'];
                          p['created_at'] = row['created_at'];
                          return p;
                        }).toList();
                      }
                      
                      List allOrders = [...orders, ...offlineOrders];
                      allOrders.sort((a, b) => (b['created_at'] ?? "").compareTo(a['created_at'] ?? ""));

                      return Column(
                        children: [
                          Padding(padding: const EdgeInsets.all(20), child: Align(alignment: Alignment.centerLeft, child: Text("🧾 ປະຫວັດການຂາຍ", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.onSurface)))),
                          Expanded(
                            child: allOrders.isEmpty ? Center(child: Text("ຍັງບໍ່ມີການຂາຍ", style: TextStyle(color: colorScheme.onSurfaceVariant)))
                            : ListView.builder(
                                itemCount: allOrders.length, 
                                itemBuilder: (context, index) {
                                  final order = allOrders[index];
                                  bool isOffline = order['id'].toString().startsWith("OFFLINE");
                                  List items = order['items'] ?? []; 
                                  int seqNum = allOrders.length - index; 
                                  double totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;

                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: isOffline ? Colors.orange.shade300 : colorScheme.outline)),
                                    child: ExpansionTile(
                                      shape: const Border(),
                                      leading: Container(
                                        width: 55, height: 55,
                                        decoration: BoxDecoration(color: isOffline ? (widget.isDarkMode ? Colors.orange.shade900 : Colors.orange[50]) : Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: isOffline ? Colors.orange.shade300 : colorScheme.outline)),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(isOffline ? "Offline" : "ບິນທີ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isOffline ? (widget.isDarkMode ? Colors.orange.shade200 : Colors.orange[800]) : colorScheme.onSurfaceVariant)),
                                            Text(isOffline ? "Q$seqNum" : "${order['id']}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isOffline ? (widget.isDarkMode ? Colors.white : Colors.orange[900]) : colorScheme.primary)),
                                          ]
                                        )
                                      ),
                                      title: Text("${NumberFormat("#,##0").format(totalAmount)} LAK", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.secondary)), 
                                      subtitle: Text("${order['created_at']?.substring(11, 16) ?? ''} · ${order['payment_method']} ${isOffline ? '(ຍັງບໍ່ຊິງຄ໌)' : ''}", style: TextStyle(color: colorScheme.onSurfaceVariant)), 
                                      children: [
                                        Divider(color: colorScheme.outline, height: 1),
                                        ...items.map((item) {
                                          double itemPrice = (item['price_at_sale'] as num?)?.toDouble() ?? 0.0;
                                          int itemQty = (item['quantity'] as num?)?.toInt() ?? 1;
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text("${itemQty}x", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 16)), const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(item['product_name'] ?? 'Unknown Item', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface, fontSize: 16)),
                                                      if (item['item_type'] != null && item['item_type'].toString().isNotEmpty) Text("${item['item_type']} · Sweet ${item['sweetness']}", style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                                                      if (item['note'] != null && item['note'].toString().isNotEmpty) Text("Note: ${item['note']}", style: TextStyle(color: Colors.red[400], fontSize: 13, fontStyle: FontStyle.italic)),
                                                    ],
                                                  )
                                                ),
                                                Text("${NumberFormat("#,##0").format(itemPrice * itemQty)} LAK", style: TextStyle(color: colorScheme.onSurface)),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton.icon(
                                              icon: const Icon(Icons.undo, color: Colors.redAccent, size: 18), label: const Text("ຍົກເລີກບິນ (Refund)", style: TextStyle(color: Colors.redAccent)),
                                              onPressed: () {
                                                showDialog(
                                                  context: context, 
                                                  builder: (_) => AlertDialog(
                                                    backgroundColor: Theme.of(context).scaffoldBackgroundColor, title: Text("⚠️ ຍົກເລີກບິນ?", style: TextStyle(color: colorScheme.onSurface)), content: Text("ຍົກເລີກບິນແລ້ວຄືນສິນຄ້າເຂົ້າ Stock ແມ່ນບໍ່?", style: TextStyle(color: colorScheme.onSurfaceVariant)),
                                                    actions: [
                                                      TextButton(onPressed: () => Navigator.pop(context), child: Text("ບໍ່ (Cancel)", style: TextStyle(color: colorScheme.onSurfaceVariant))),
                                                      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () { Navigator.pop(context); Navigator.pop(context); processRefund(order['id']); }, child: const Text("ຢືນຢັນ (Refund)", style: TextStyle(color: Colors.white)))
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
                  );
                }
              )
            );
          }
        );
      }
    );
  }

  List<ProductModel> getFilteredProducts() { 
    if (selectedCategory == "All") return products; 
    return products.where((i) => i.category == selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fmt = NumberFormat("#,##0");
    double totalCartPrice = cart.fold(0.0, (sum, item) => sum + (item.price * item.qty));
    int totalItems = cart.fold(0, (sum, item) => sum + item.qty);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sumday ☕"), 
        actions: [
          IconButton(onPressed: widget.toggleTheme, icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode, color: colorScheme.onSurfaceVariant)),
          IconButton(onPressed: showHeldBillsDialog, icon: const Icon(Icons.access_time)), 
          IconButton(onPressed: showOrderHistory, icon: const Icon(Icons.receipt_long)), 
          IconButton(onPressed: showAddProductDialog, icon: Icon(Icons.add_box_outlined, color: colorScheme.secondary)), 
          const SizedBox(width: 10),
        ]
      ),
      body: RefreshIndicator(
        onRefresh: fetchProducts,
        color: colorScheme.primary, backgroundColor: colorScheme.surface,
        child: Column(
          children: [
            Container(
              height: 60, padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10), 
              child: ListView(
                scrollDirection: Axis.horizontal, 
                children: categories.map((c) {
                  bool isSelected = selectedCategory == c;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10), 
                    child: ElevatedButton(
                      onPressed: () => setState(() => selectedCategory = c), 
                      style: ElevatedButton.styleFrom(
                        elevation: 0, backgroundColor: isSelected ? colorScheme.primary : colorScheme.surface, foregroundColor: isSelected ? (widget.isDarkMode ? softBlackDark : paperWhite) : colorScheme.onSurface, 
                        side: BorderSide(color: isSelected ? colorScheme.primary : colorScheme.outline), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 20)
                      ), 
                      child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold))
                    )
                  );
                }).toList()
              )
            ),
            
            Expanded(
              child: selectedCategory == "About CEO" 
              ? Center(
                  child: SingleChildScrollView( 
                    physics: const AlwaysScrollableScrollPhysics(), 
                    child: Container(
                      width: 300, padding: const EdgeInsets.all(30), decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: colorScheme.outline), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, 
                        children: [
                          ClipRRect(borderRadius: BorderRadius.circular(100), child: Image.asset("assets/sumday.jpg", fit: BoxFit.cover, height: 120, width: 120, errorBuilder: (_,__,___)=> const Icon(Icons.person, size: 80))),
                          const SizedBox(height: 20), 
                          Text("MR. MICK", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.onSurface, letterSpacing: 1)), 
                          Text("Founder & CEO", style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic)), 
                          const SizedBox(height: 15), 
                          Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5), decoration: BoxDecoration(color: colorScheme.secondary, borderRadius: BorderRadius.circular(20)), child: Text("Priceless 💎", style: TextStyle(fontSize: 14, color: widget.isDarkMode ? softBlackDark : paperWhite, fontWeight: FontWeight.bold))), 
                        ]
                      )
                    ),
                  )
                )
              : isLoading 
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary)) 
                : GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(), 
                    padding: const EdgeInsets.all(15), 
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.85, crossAxisSpacing: 15, mainAxisSpacing: 15), 
                    itemCount: getFilteredProducts().length, 
                    itemBuilder: (context, index) {
                      final item = getFilteredProducts()[index];
                      bool isOutOfStock = item.stock <= 0;
                      return GestureDetector(
                        onTap: isOutOfStock ? null : () => openProductOptionDialog(item), 
                        onLongPress: () => showManageOptions(index, item), 
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: isOutOfStock ? Theme.of(context).scaffoldBackgroundColor : colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: colorScheme.outline)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center, 
                            children: [ 
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(8)),
                                  child: item.image.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        item.image, width: double.infinity, height: double.infinity, fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Center(child: Icon(getCategoryIcon(item.category), size: 45, color: isOutOfStock ? colorScheme.onSurfaceVariant : colorScheme.primary)),
                                      ),
                                    )
                                  : Center(child: Icon(getCategoryIcon(item.category), size: 45, color: isOutOfStock ? colorScheme.onSurfaceVariant : colorScheme.primary))
                                )
                              ), 
                              const SizedBox(height: 12), 
                              Text(item.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isOutOfStock ? colorScheme.onSurfaceVariant : colorScheme.onSurface), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis), 
                              const SizedBox(height: 4), 
                              Text("${fmt.format(item.price)} ກີບ", style: TextStyle(fontSize: 14, color: isOutOfStock ? colorScheme.onSurfaceVariant : colorScheme.secondary, fontWeight: FontWeight.bold)), 
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
        color: colorScheme.surface, elevation: 10,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("ກະຕ່າ ($totalItems ລາຍການ)", style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                  Text("${fmt.format(totalCartPrice)} LAK", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: showCartDialog, 
                icon: Icon(Icons.shopping_cart, color: widget.isDarkMode ? softBlackDark : paperWhite), 
                label: Text("ຈ່າຍເງິນ (View)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: widget.isDarkMode ? softBlackDark : paperWhite)),
                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              )
            ],
          ),
        ),
      ),
    );
  }
}