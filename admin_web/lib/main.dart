import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(const AdminWebApp());
}

class AdminWebApp extends StatelessWidget {
  const AdminWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coffee POS Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.brown, 
        useMaterial3: true,
        fontFamily: 'NotoSansLao', 
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0; 
  final List<Widget> _pages = [
    const DashboardScreen(),      
    const ProductManagerScreen(), 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.white,
            elevation: 5,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('ພາບລວມ')),
              NavigationRailDestination(icon: Icon(Icons.coffee), label: Text('ສິນຄ້າ & Stock')), // ⭐ เปลี่ยนชื่อเมนู
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}

// ⭐ ฟังก์ชันช่วยแปลงตัวเลข
double safeParse(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  String cleanValue = value.toString().replaceAll(',', '');
  return double.tryParse(cleanValue) ?? 0.0;
}

// ---------------- DASHBOARD (คงเดิม: โชว์รายละเอียด ความหวาน/หมายเหตุ) ----------------
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List orders = [];
  double totalRevenue = 0;
  bool isLoading = false;
  
  // ⚠️ เช็ค IP ให้ตรงกับ Backend
  final String apiUrl = "http://192.168.1.6:8000/orders"; 

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    setState(() => isLoading = true); 
    try {
      var response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        double total = 0;
        for (var order in data) {
          total += safeParse(order['total_amount']);
        }
        setState(() {
          orders = data.reversed.toList();
          totalRevenue = total;
          isLoading = false; 
        });
      }
    } catch (e) { 
      print("Error: $e"); 
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0", "lo_LA");
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"), 
        backgroundColor: Colors.white, 
        elevation: 0,
        actions: [
          IconButton(
            onPressed: fetchOrders, 
            icon: const Icon(Icons.refresh, color: Colors.brown),
            tooltip: "Refresh Data",
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchOrders,
        color: Colors.brown,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // กล่องยอดรวม
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green[600], 
                  borderRadius: BorderRadius.circular(15), 
                  boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 10)]
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.attach_money, size: 40, color: Colors.white),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("ຍອດຂາຍລວມ (Total Revenue)", style: TextStyle(fontSize: 16, color: Colors.white)),
                        isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text("${currencyFormat.format(totalRevenue)} ກີບ", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // รายการออเดอร์
              Expanded(
                child: orders.isEmpty 
                  ? Center(child: Text(isLoading ? "ກຳລັງໂຫລດ..." : "ຍັງບໍ່ມີການຂາຍ", style: const TextStyle(color: Colors.grey)))
                  : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.brown[100], 
                            child: Text("#${order['id']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                          ),
                          title: Text("Order #${order['id']} - ${order['created_at'] != null ? order['created_at'].toString().substring(0, 16) : ''}"),
                          subtitle: Text("Total: ${currencyFormat.format(safeParse(order['total_amount']))} ກີບ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          children: [
                            Container(
                              color: Colors.grey[50],
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                children: (order['items'] as List).map<Widget>((item) {
                                  var product = item['product'];
                                  String pName = product != null ? product['name'] : "Unknown Product";
                                  
                                  String details = "${item['item_type'] ?? ''} | Sweet ${item['sweetness'] ?? ''}";
                                  String note = item['note'] ?? "";

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // จำนวน
                                        Text("${item['quantity']}x ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.brown)),
                                        const SizedBox(width: 10),
                                        // รายละเอียด
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(pName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              if (item['item_type'] != null || item['sweetness'] != null)
                                                Text(details, style: TextStyle(color: Colors.blue[800], fontSize: 13)),
                                              if (note.isNotEmpty) 
                                                Text("Note: $note", style: TextStyle(color: Colors.red[400], fontSize: 12, fontStyle: FontStyle.italic)),
                                            ],
                                          ),
                                        ),
                                        // ราคา
                                        Text(currencyFormat.format(safeParse(item['price_at_sale']) * item['quantity']), style: TextStyle(color: Colors.grey[600])),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- PRODUCT MANAGER (เพิ่ม Stock เข้าไปในโค้ดเดิมของคุณ) ----------------
class ProductManagerScreen extends StatefulWidget {
  const ProductManagerScreen({super.key});
  @override
  State<ProductManagerScreen> createState() => _ProductManagerScreenState();
}

class _ProductManagerScreenState extends State<ProductManagerScreen> {
  List products = [];
  bool showBin = false; 
  
  // ⚠️ เช็ค IP ให้ตรงกับ Backend
  final String apiUrl = "http://127.0.0.1:8000/products";
  
  final List<String> categories = ["All", "Coffee", "Tea", "Dessert", "Other"];
  String selectedCategory = "All"; 

  @override
  void initState() { super.initState(); fetchProducts(); }

  Future<void> fetchProducts() async {
    try {
      var url = Uri.parse("$apiUrl?show_all=$showBin");
      var response = await http.get(url);
      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        data.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
        setState(() { products = data; });
      }
    } catch (e) { print(e); }
  }

  List getFilteredProducts() {
    List temp;
    if (showBin) {
      temp = products.where((item) => item['is_active'] == false).toList();
    } else {
      temp = products.where((item) => item['is_active'] == true).toList();
    }

    if (selectedCategory == "All") return temp;
    return temp.where((item) => item['category'] == selectedCategory).toList();
  }

  // ⭐ อัปเดต: เพิ่มการรับค่า stock
  Future<void> addProduct(String name, String price, String category, String stock) async {
    await http.post(Uri.parse(apiUrl), headers: {"Content-Type": "application/json"},
      body: json.encode({
        "name": name, 
        "category": category, 
        "price": safeParse(price), 
        "stock": int.tryParse(stock) ?? 0, // ⭐ ส่ง stock ไป
        "is_active": true
      }));
    fetchProducts();
    if(mounted) Navigator.pop(context);
  }

  // ⭐ อัปเดต: เพิ่มการรับค่า stock
  Future<void> updateProduct(int id, String name, String price, String category, String stock) async {
    await http.put(Uri.parse("$apiUrl/$id"), headers: {"Content-Type": "application/json"},
      body: json.encode({
        "name": name, 
        "category": category, 
        "price": safeParse(price), 
        "stock": int.tryParse(stock) ?? 0, // ⭐ ส่ง stock ไป
        "is_active": true
      }));
    fetchProducts();
    if(mounted) Navigator.pop(context);
  }

  Future<void> deleteProduct(int id) async {
    await http.delete(Uri.parse("$apiUrl/$id"));
    fetchProducts();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ລຶບສິນຄ້າແລ້ວ (ໄປທີ່ຖັງຂຍະເພື່ອການກູ້ຄືນ)"), duration: Duration(seconds: 2)));
  }

  Future<void> restoreProduct(int id) async {
    await http.put(Uri.parse("$apiUrl/$id/restore"));
    fetchProducts();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ກູ້ຄືນສິນຄ້າຮຽບຮ້ອຍ! 🎉"), backgroundColor: Colors.green));
  }

  void showProductDialog({Map? item}) {
    bool isEdit = item != null;
    TextEditingController n = TextEditingController(text: isEdit ? item['name'] : "");
    TextEditingController p = TextEditingController(text: isEdit ? NumberFormat("#,##0").format(safeParse(item['price'])) : "");
    // ⭐ เพิ่มช่องกรอก Stock
    TextEditingController s = TextEditingController(text: isEdit ? item['stock'].toString() : "0"); 

    String cat = isEdit ? item['category'] : "Coffee"; 
    List<String> cats = categories.where((c) => c != "All").toList();

    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(isEdit ? "ແກ້ໄຂສິນຄ້າ" : "ເພີ່ມສິນຄ້າ"),
      content: StatefulBuilder(builder: (context, setState) => Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: n, decoration: const InputDecoration(labelText: "ຊື່ສິນຄ້າ")),
        
        // ⭐ จัด Price กับ Stock ให้อยู่แถวเดียวกัน
        Row(
          children: [
            Expanded(child: TextField(controller: p, decoration: const InputDecoration(labelText: "ລາຄາ"), keyboardType: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: s, decoration: const InputDecoration(labelText: "Stock (ຈຳນວນ)"), keyboardType: TextInputType.number)),
          ],
        ),
        
        const SizedBox(height: 15),
        DropdownButtonFormField<String>(value: cat, items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setState(() => cat = v!), decoration: const InputDecoration(labelText: "ໝວດໝູ່")),
      ])),
      actions: [
        ElevatedButton(
          onPressed: () => isEdit 
            ? updateProduct(item['id'], n.text, p.text, cat, s.text) 
            : addProduct(n.text, p.text, cat, s.text), 
          child: const Text("ບັນທຶກ")
        )
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(showBin ? "ສິນຄ້າທີ່ຖືກລົບ (Recycle Bin)" : "Product & Stock Manager"),
        backgroundColor: showBin ? Colors.grey[300] : Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() { showBin = !showBin; });
              fetchProducts();
            },
            icon: Icon(showBin ? Icons.list : Icons.delete_outline, color: showBin ? Colors.black : Colors.red),
            label: Text(showBin ? "ກັບໄປหน้ารายການ" : "ຖັງຂຍະ (Bin)", style: TextStyle(color: showBin ? Colors.black : Colors.red)),
          ),
          const SizedBox(width: 10),
          IconButton(onPressed: fetchProducts, icon: const Icon(Icons.refresh, color: Colors.brown))
        ],
      ),
      floatingActionButton: showBin ? null : FloatingActionButton.extended(
        onPressed: () => showProductDialog(),
        backgroundColor: Colors.brown,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("ເພີ່ມສິນຄ້າ", style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          if (!showBin)
            Container(height: 60, padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20), child: ListView(scrollDirection: Axis.horizontal, children: categories.map((c) => Padding(padding: const EdgeInsets.only(right: 10), child: ElevatedButton(onPressed: () => setState(() => selectedCategory = c), style: ElevatedButton.styleFrom(backgroundColor: selectedCategory == c ? Colors.brown : Colors.white, foregroundColor: selectedCategory == c ? Colors.white : Colors.brown, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.brown))), child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold))))).toList())),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: getFilteredProducts().isEmpty 
                ? Center(child: Text(showBin ? "ບໍ່ມີສິນຄ້າໃນຖັງຂຍະ" : "ບໍ່ມີສິນຄ້າ", style: const TextStyle(color: Colors.grey)))
                : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5, 
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: getFilteredProducts().length,
                  itemBuilder: (context, index) {
                    final item = getFilteredProducts()[index];
                    // ⭐ เช็คว่าของหมดไหม
                    bool outOfStock = (item['stock'] ?? 0) <= 0;
                    
                    return InkWell(
                      onTap: () => showBin ? null : showProductDialog(item: item),
                      child: Card(
                        elevation: 3,
                        color: showBin ? Colors.grey[200] : null,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  // ⭐ ถ้าของหมดให้พื้นหลังเป็นสีเทา
                                  color: outOfStock ? Colors.grey[300] : (showBin ? Colors.grey[400] : Colors.brown[50]), 
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                ),
                                child: Stack(
                                  children: [
                                    Center(child: Icon(Icons.coffee, size: 60, color: showBin ? Colors.white : (outOfStock ? Colors.grey : Colors.brown))),
                                    
                                    // ปุ่มลบ/กู้คืน
                                    Positioned(
                                      top: 5,
                                      right: 5,
                                      child: IconButton(
                                        icon: Icon(showBin ? Icons.restore : Icons.delete, color: showBin ? Colors.green[800] : Colors.red),
                                        onPressed: () => showBin ? restoreProduct(item['id']) : deleteProduct(item['id']),
                                        tooltip: showBin ? "ກູ້ຄືນ (Restore)" : "ລຶບ (Delete)",
                                      ),
                                    ),

                                    // ⭐ ป้าย Stock (โชว์เฉพาะตอนไม่ใช่ถังขยะ)
                                    if (!showBin)
                                      Positioned(
                                        top: 5, left: 5,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: outOfStock ? Colors.red : Colors.green, // แดงถ้าหมด เขียวถ้ามี
                                            borderRadius: BorderRadius.circular(10)
                                          ),
                                          child: Text(
                                            "Stock: ${item['stock']}", 
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)
                                          ),
                                        ),
                                      )
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                children: [
                                  Text(item['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, decoration: showBin ? TextDecoration.lineThrough : null, color: showBin ? Colors.grey : null), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 5),
                                  Text("${NumberFormat("#,##0").format(safeParse(item['price']))} ກີບ", style: TextStyle(color: showBin ? Colors.grey : Colors.brown[700], fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ),
          ),
        ],
      ),
    );
  }
}