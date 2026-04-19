import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() { runApp(const BackOfficeApp()); }

// 🎨 --- Color Palette ---
const Color bgBaseLight = Color(0xFFF0EBE1);
const Color surfaceWhite = Color(0xFFFFFFFF);
const Color earthBrownLight = Color(0xFF4A3628);
const Color mossGreenLight = Color(0xFF5A6B47);
const Color softBlackLight = Color(0xFF1E1E1E);
const Color borderColorLight = Color(0xFFDCD3C6);
const Color mutedTextLight = Color(0xFF7A7A7A);

const Color bgBaseDark = Color(0xFF1A1817); 
const Color surfaceDark = Color(0xFF242220); 
const Color earthBrownDark = Color(0xFFD4B895); 
const Color mossGreenDark = Color(0xFF8BA372); 
const Color softBlackDark = Color(0xFFF9F6F0); 
const Color borderColorDark = Color(0xFF383431); 
const Color mutedTextDark = Color(0xFF8A847D);

// 🔌 URL กลาง ชี้ไปที่ Dell Server ของนาย
const String serverUrl = "http://192.168.1.50:8000";

class BackOfficeApp extends StatefulWidget {
  const BackOfficeApp({super.key});
  @override
  State<BackOfficeApp> createState() => _BackOfficeAppState();
}

class _BackOfficeAppState extends State<BackOfficeApp> {
  bool isDarkMode = true;

  void toggleTheme() { setState(() { isDarkMode = !isDarkMode; }); }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sumday Back Office',
      debugShowCheckedModeBanner: false,
      theme: isDarkMode ? _buildDarkTheme() : _buildLightTheme(),
      home: DashboardScreen(isDarkMode: isDarkMode, toggleTheme: toggleTheme),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light, scaffoldBackgroundColor: bgBaseLight, fontFamily: 'serif',
      colorScheme: const ColorScheme.light(primary: earthBrownLight, secondary: mossGreenLight, surface: surfaceWhite, onSurface: softBlackLight, outline: borderColorLight, onSurfaceVariant: mutedTextLight),
      useMaterial3: true,
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark, scaffoldBackgroundColor: bgBaseDark, fontFamily: 'serif',
      colorScheme: const ColorScheme.dark(primary: earthBrownDark, secondary: mossGreenDark, surface: surfaceDark, onSurface: softBlackDark, outline: borderColorDark, onSurfaceVariant: mutedTextDark),
      useMaterial3: true,
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;
  const DashboardScreen({super.key, required this.isDarkMode, required this.toggleTheme});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _menuAnalytics = [
    {"icon": Icons.space_dashboard_outlined, "title": "ສະຫຼຸບຍອດຂາຍ (Dashboard)"},
    {"icon": Icons.bar_chart_rounded, "title": "ຍອດຂາຍຕາມສິນຄ້າ"},
    {"icon": Icons.pie_chart_outline, "title": "ຍອດຂາຍແຍກຕາມໝວດໝູ່"},
  ];

  final List<Map<String, dynamic>> _menuManagement = [
    {"icon": Icons.receipt_long_outlined, "title": "ໃບເສັດຮັບເງິນ (Order History)"},
    {"icon": Icons.coffee_maker_outlined, "title": "ລາຍການສິນຄ້າ (Menu List)"},
    {"icon": Icons.category_outlined, "title": "ໝວດໝູ່ (Categories)"},
    {"icon": Icons.settings_outlined, "title": "ຕັ້ງຄ່າລະບົບ (Settings)"},
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          // 👈 --- SIDEBAR ---
          Container(
            width: 260,
            decoration: BoxDecoration(color: colorScheme.surface, border: Border(right: BorderSide(color: colorScheme.outline, width: 1))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(30, 40, 30, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Sumday ☕", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: colorScheme.onSurface, letterSpacing: 1.2)),
                      const SizedBox(height: 5),
                      Text("Back Office System", style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 20),
                    children: [
                      _buildSectionHeader("ລາຍງານ (ANALYTICS)", colorScheme),
                      ..._menuAnalytics.asMap().entries.map((e) => _buildMenuItem(e.key, e.value['title'], e.value['icon'], colorScheme)),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Divider(color: colorScheme.outline, height: 40)),
                      _buildSectionHeader("ຈັດການຮ້ານ (MANAGEMENT)", colorScheme),
                      ..._menuManagement.asMap().entries.map((e) => _buildMenuItem(e.key + _menuAnalytics.length, e.value['title'], e.value['icon'], colorScheme)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: colorScheme.outline))),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [Icon(widget.isDarkMode ? Icons.dark_mode : Icons.light_mode, size: 18, color: colorScheme.onSurfaceVariant), const SizedBox(width: 10), Text("Dark Mode", style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, fontFamily: 'sans-serif'))]),
                          Switch(value: widget.isDarkMode, onChanged: (val) => widget.toggleTheme(), activeColor: colorScheme.primary, activeTrackColor: colorScheme.primary.withOpacity(0.3))
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          CircleAvatar(backgroundColor: Theme.of(context).scaffoldBackgroundColor, child: Icon(Icons.person_outline, color: colorScheme.primary)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("MR. MICK", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onSurface, fontFamily: 'sans-serif')),
                                Row(children: [Icon(Icons.circle, size: 8, color: colorScheme.secondary), const SizedBox(width: 6), Text("Online", style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, fontFamily: 'sans-serif'))])
                              ],
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          // 👉 --- MAIN CONTENT ---
          Expanded(child: Container(color: Theme.of(context).scaffoldBackgroundColor, child: _buildContent(colorScheme))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Padding(padding: const EdgeInsets.only(left: 30, bottom: 10, top: 10), child: Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: colorScheme.onSurfaceVariant, fontFamily: 'sans-serif')));
  }

  Widget _buildMenuItem(int index, String title, IconData icon, ColorScheme colorScheme) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: isSelected ? colorScheme.primary.withOpacity(0.08) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant),
            const SizedBox(width: 14),
            Expanded(child: Text(title, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.7), fontFamily: 'sans-serif'))),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme colorScheme) {
    List<Widget> pages = [
      DashboardView(colorScheme: colorScheme),
      SalesByProductView(colorScheme: colorScheme),
      SalesByCategoryView(colorScheme: colorScheme), 
      Center(child: Text("ໃບເສັດຮັບເງິນ (Order History) - Coming Soon", style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 18, fontStyle: FontStyle.italic))),
      ProductManagerView(colorScheme: colorScheme), // 🎯 รวมหน้า Product Manager เข้า Index ที่ 4
    ];

    while (pages.length < _menuAnalytics.length + _menuManagement.length) {
      pages.add(Center(child: Text("ກຳລັງພັດທະນາ (Coming Soon)", style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 18, fontStyle: FontStyle.italic))));
    }

    return IndexedStack(
      index: _selectedIndex,
      children: pages,
    );
  }
}

double safeParse(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  String cleanValue = value.toString().replaceAll(',', '');
  return double.tryParse(cleanValue) ?? 0.0;
}

// 📦 --- หน้า Product Manager (ผสาน UI ใหม่เข้ากับ Logic เดิม) ---
class ProductManagerView extends StatefulWidget {
  final ColorScheme colorScheme;
  const ProductManagerView({super.key, required this.colorScheme});

  @override
  State<ProductManagerView> createState() => _ProductManagerViewState();
}

class _ProductManagerViewState extends State<ProductManagerView> {
  List products = [];
  bool showBin = false;
  final List<String> categories = ["All", "Coffee", "Tea", "Dessert", "Other"];
  String selectedCategory = "All"; 
  bool isLoading = false;

  @override
  void initState() { 
    super.initState(); 
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    setState(() => isLoading = true);
    try {
      var url = Uri.parse("$serverUrl/products?show_all=$showBin");
      var response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        data.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
        setState(() { products = data; });
      }
    } catch (e) { 
      print("Error fetching products: $e"); 
    } finally {
      setState(() => isLoading = false);
    }
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

  Future<void> addProduct(String name, String price, String category, String stock) async {
    await http.post(Uri.parse("$serverUrl/products"), headers: {"Content-Type": "application/json"},
      body: json.encode({
        "name": name, 
        "category": category, 
        "price": safeParse(price), 
        "stock": int.tryParse(stock) ?? 0,
        "is_active": true
      }));
    fetchProducts();
    if(mounted) Navigator.pop(context);
  }

  Future<void> updateProduct(int id, String name, String price, String category, String stock) async {
    await http.put(Uri.parse("$serverUrl/products/$id"), headers: {"Content-Type": "application/json"},
      body: json.encode({
        "name": name, 
        "category": category, 
        "price": safeParse(price), 
        "stock": int.tryParse(stock) ?? 0,
        "is_active": true
      }));
    fetchProducts();
    if(mounted) Navigator.pop(context);
  }

  Future<void> deleteProduct(int id) async {
    await http.delete(Uri.parse("$serverUrl/products/$id"));
    fetchProducts();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("ລຶບສິນຄ້າແລ້ວ (ຍ້າຍໄປຖັງຂຍະ)"), backgroundColor: widget.colorScheme.error));
  }

  Future<void> restoreProduct(int id) async {
    await http.put(Uri.parse("$serverUrl/products/$id/restore"));
    fetchProducts();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("ກູ້ຄືນສິນຄ້າຮຽບຮ້ອຍ! 🎉"), backgroundColor: widget.colorScheme.primary));
  }

  void showProductDialog({Map? item}) {
    bool isEdit = item != null;
    TextEditingController n = TextEditingController(text: isEdit ? item['name'] : "");
    TextEditingController p = TextEditingController(text: isEdit ? NumberFormat("#,##0").format(safeParse(item['price'])) : "");
    TextEditingController s = TextEditingController(text: isEdit ? item['stock'].toString() : "0");
    String cat = isEdit ? item['category'] : "Coffee"; 
    List<String> cats = categories.where((c) => c != "All").toList();

    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: widget.colorScheme.surface,
      title: Text(isEdit ? "ແກ້ໄຂສິນຄ້າ" : "ເພີ່ມສິນຄ້າ", style: TextStyle(color: widget.colorScheme.onSurface)),
      content: StatefulBuilder(builder: (context, setState) => Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: n, style: TextStyle(color: widget.colorScheme.onSurface), decoration: InputDecoration(labelText: "ຊື່ສິນຄ້າ", labelStyle: TextStyle(color: widget.colorScheme.onSurfaceVariant))),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: TextField(controller: p, style: TextStyle(color: widget.colorScheme.onSurface), decoration: InputDecoration(labelText: "ລາຄາ", labelStyle: TextStyle(color: widget.colorScheme.onSurfaceVariant)), keyboardType: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: s, style: TextStyle(color: widget.colorScheme.onSurface), decoration: InputDecoration(labelText: "Stock", labelStyle: TextStyle(color: widget.colorScheme.onSurfaceVariant)), keyboardType: TextInputType.number)),
          ],
        ),
        const SizedBox(height: 15),
        DropdownButtonFormField<String>(
          value: cat, 
          dropdownColor: widget.colorScheme.surface,
          items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: widget.colorScheme.onSurface)))).toList(), 
          onChanged: (v) => setState(() => cat = v!), 
          decoration: InputDecoration(labelText: "ໝວດໝູ່", labelStyle: TextStyle(color: widget.colorScheme.onSurfaceVariant))
        ),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text("ຍົກເລີກ", style: TextStyle(color: widget.colorScheme.onSurfaceVariant))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: widget.colorScheme.primary, foregroundColor: widget.colorScheme.onPrimary),
          onPressed: () => isEdit ? updateProduct(item['id'], n.text, p.text, cat, s.text) : addProduct(n.text, p.text, cat, s.text), 
          child: const Text("ບັນທຶກ")
        )
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(showBin ? "ສິນຄ້າທີ່ຖືກລົບ (Recycle Bin)" : "ລາຍການສິນຄ້າ (Menu & Stock)", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                  const SizedBox(height: 6),
                  Text("ຈັດການສິນຄ້າ, ລາຄາ ແລະ ສະຕ໋ອກພາຍໃນຮ້ານ", style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, fontFamily: 'sans-serif')),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() { showBin = !showBin; });
                      fetchProducts();
                    }, 
                    icon: Icon(showBin ? Icons.list : Icons.delete_outline, size: 18, color: showBin ? colorScheme.onSurface : Colors.red), 
                    label: Text(showBin ? "ກັບໄປໜ້າລາຍການ" : "ຖັງຂຍະ (Bin)", style: TextStyle(color: showBin ? colorScheme.onSurface : Colors.red)),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: showBin ? colorScheme.outline : Colors.red.withOpacity(0.5)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => showProductDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("ເພີ່ມສິນຄ້າ"),
                    style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                  ),
                  const SizedBox(width: 12),
                  IconButton(onPressed: fetchProducts, icon: Icon(Icons.refresh, color: colorScheme.onSurfaceVariant)),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          
          if (!showBin)
            Container(
              height: 50, 
              margin: const EdgeInsets.only(bottom: 20),
              child: ListView(
                scrollDirection: Axis.horizontal, 
                children: categories.map((c) {
                  bool isSelected = selectedCategory == c;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10), 
                    child: ElevatedButton(
                      onPressed: () => setState(() => selectedCategory = c), 
                      style: ElevatedButton.styleFrom(
                        elevation: 0, backgroundColor: isSelected ? colorScheme.primary : colorScheme.surface, 
                        foregroundColor: isSelected ? colorScheme.onPrimary : colorScheme.onSurface, 
                        side: BorderSide(color: isSelected ? colorScheme.primary : colorScheme.outline), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                      ), 
                      child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'sans-serif'))
                    )
                  );
                }).toList()
              )
            ),
            
          Expanded(
            child: isLoading 
              ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
              : getFilteredProducts().isEmpty 
                ? Center(child: Text(showBin ? "ບໍ່ມີສິນຄ້າໃນຖັງຂຍະ" : "ບໍ່ມີສິນຄ້າ", style: TextStyle(color: colorScheme.onSurfaceVariant)))
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 0.8, crossAxisSpacing: 15, mainAxisSpacing: 15),
                    itemCount: getFilteredProducts().length,
                    itemBuilder: (context, index) {
                      final item = getFilteredProducts()[index];
                      bool outOfStock = (item['stock'] ?? 0) <= 0;
                      
                      return InkWell(
                        onTap: () => showBin ? null : showProductDialog(item: item),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: colorScheme.outline)),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Container(
                                  color: outOfStock ? colorScheme.surface.withOpacity(0.5) : Theme.of(context).scaffoldBackgroundColor,
                                  child: Stack(
                                    children: [
                                      Center(child: Icon(Icons.coffee, size: 50, color: outOfStock ? colorScheme.onSurfaceVariant.withOpacity(0.5) : colorScheme.primary.withOpacity(0.7))),
                                      Positioned(
                                        top: 5, right: 5,
                                        child: IconButton(
                                          icon: Icon(showBin ? Icons.restore : Icons.delete, size: 20, color: showBin ? colorScheme.secondary : Colors.redAccent),
                                          onPressed: () => showBin ? restoreProduct(item['id']) : deleteProduct(item['id']),
                                          tooltip: showBin ? "ກູ້ຄືນ" : "ລຶບ",
                                        ),
                                      ),
                                      if (!showBin)
                                        Positioned(
                                          top: 10, left: 10,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: outOfStock ? Colors.redAccent : colorScheme.secondary, borderRadius: BorderRadius.circular(8)),
                                            child: Text("Stock: ${item['stock']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                                          ),
                                        )
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    Text(item['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, decoration: showBin ? TextDecoration.lineThrough : null, color: showBin ? colorScheme.onSurfaceVariant : colorScheme.onSurface, fontFamily: 'sans-serif'), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text("${NumberFormat("#,##0").format(safeParse(item['price']))} ກີບ", style: TextStyle(color: showBin ? colorScheme.onSurfaceVariant : colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
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
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// ด้านล่างคือ Dashboard, SalesByProduct, SalesByCategory จากโค้ดเดิมทั้งหมด
// ยกมาวางต่อกันให้ระบบทำงานครบ Loop (ไม่มีการแก้ไขตรรกะเดิม แค่รวมไฟล์)
// ----------------------------------------------------------------------

class DashboardView extends StatefulWidget {
  final ColorScheme colorScheme;
  const DashboardView({super.key, required this.colorScheme});
  @override
  State<DashboardView> createState() => _DashboardViewState();
}
class _DashboardViewState extends State<DashboardView> {
  bool isLoading = true;
  double netSales = 0;
  int totalBills = 0;
  List<Map<String, dynamic>> topProducts = [];
  List<Map<String, dynamic>> dailyReport = [];
  DateTimeRange? selectedDateRange;

  @override
  void initState() { super.initState(); fetchAnalyticsData(); }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context, firstDate: DateTime(2020), lastDate: DateTime.now(), initialDateRange: selectedDateRange,
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: widget.colorScheme.copyWith(primary: widget.colorScheme.primary, surface: widget.colorScheme.surface, onPrimary: widget.colorScheme.surface, onSurface: widget.colorScheme.onSurface)), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400, maxHeight: 550), child: child!))),
    );
    if (picked != null) { setState(() => selectedDateRange = picked); fetchAnalyticsData(); }
  }

  Future<void> fetchAnalyticsData() async {
    setState(() => isLoading = true);
    try {
      var response = await http.get(Uri.parse('$serverUrl/orders')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) { _calculateMetrics(json.decode(utf8.decode(response.bodyBytes))); }
    } catch (e) { print("Error: $e"); } finally { setState(() => isLoading = false); }
  }

  void _calculateMetrics(List orders) {
    netSales = 0; totalBills = orders.length;
    Map<String, double> productSalesMap = {}; Map<String, double> dailySalesMap = {};
    DateTime endDate = selectedDateRange?.end ?? DateTime.now();
    DateTime startDate = selectedDateRange?.start ?? endDate.subtract(const Duration(days: 3));
    int totalDays = endDate.difference(startDate).inDays + 1;

    for (int i = totalDays - 1; i >= 0; i--) { dailySalesMap[DateFormat('yyyy-MM-dd').format(endDate.subtract(Duration(days: i)))] = 0.0; }

    for (var order in orders) {
      double orderTotal = safeParse(order['total_amount']);
      netSales += orderTotal;
      if (order['created_at'] != null && order['created_at'].toString().length >= 10) {
        DateTime orderDate = DateTime.tryParse(order['created_at'].toString().substring(0, 10)) ?? DateTime.now();
        DateTime s = DateTime(startDate.year, startDate.month, startDate.day);
        DateTime e = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        if (orderDate.isBefore(s) || orderDate.isAfter(e)) continue; 
        String dateKey = order['created_at'].toString().substring(0, 10);
        if (dailySalesMap.containsKey(dateKey)) dailySalesMap[dateKey] = dailySalesMap[dateKey]! + orderTotal;
      }
      if (order['items'] != null) {
        for (var item in order['items']) {
          String pName = item['product_name'] ?? 'Unknown';
          productSalesMap[pName] = (productSalesMap[pName] ?? 0) + (safeParse(item['price_at_sale']) * safeParse(item['quantity']));
        }
      }
    }
    var sortedProducts = productSalesMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    topProducts = sortedProducts.take(5).map((e) => {"name": e.key, "revenue": e.value}).toList();
    dailyReport.clear();
    var sortedDates = dailySalesMap.keys.toList()..sort((a, b) => b.compareTo(a));
    for (var date in sortedDates) { dailyReport.add({"date": DateFormat('d MMM yyyy').format(DateTime.parse(date)), "rawDate": date, "revenue": dailySalesMap[date]!}); }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return Center(child: CircularProgressIndicator(color: widget.colorScheme.primary));
    final fmt = NumberFormat("#,##0");
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("ສະຫຼຸບຍອດຂາຍ (Dashboard)", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: widget.colorScheme.onSurface)), const SizedBox(height: 6), Text("ພາບລວມຍອດຂາຍ ແລະ ສະຖິຕິຮ້ານ", style: TextStyle(fontSize: 14, color: widget.colorScheme.onSurfaceVariant, fontFamily: 'sans-serif'))]),
              Row(
                children: [
                  IconButton(onPressed: fetchAnalyticsData, icon: Icon(Icons.refresh, color: widget.colorScheme.onSurfaceVariant)), const SizedBox(width: 10),
                  InkWell(onTap: () => _selectDateRange(context), borderRadius: BorderRadius.circular(8), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: widget.colorScheme.surface, border: Border.all(color: widget.colorScheme.outline), borderRadius: BorderRadius.circular(8)), child: Row(children: [Icon(Icons.calendar_month_outlined, size: 18, color: widget.colorScheme.primary), const SizedBox(width: 10), Text(selectedDateRange == null ? "4 ມື້ຫຼ້າສຸດ (Last 4 Days)" : "${DateFormat('dd MMM').format(selectedDateRange!.start)} - ${DateFormat('dd MMM').format(selectedDateRange!.end)}", style: TextStyle(fontSize: 14, color: widget.colorScheme.onSurface, fontFamily: 'sans-serif', fontWeight: FontWeight.w500)), const SizedBox(width: 10), Icon(Icons.arrow_drop_down, size: 18, color: widget.colorScheme.onSurfaceVariant)])))
                ],
              )
            ],
          ),
          const SizedBox(height: 30),
          Row(children: [_buildStatCard("ຍອດຂາຍລວມສູດທິ (Net Sales)", fmt.format(netSales), "LAK", "ຍອດຂາຍທັງໝົດ", Icons.account_balance_wallet, isPrimary: true), const SizedBox(width: 20), _buildStatCard("ຈຳນວນບິນ (Total Bills)", "$totalBills", "Bills", "ຈຳນວນບິນທັງໝົດ", Icons.receipt_long), const SizedBox(width: 20), _buildStatCard("ສະເລ່ຍຕໍ່ບິນ (Avg/Bill)", totalBills > 0 ? fmt.format(netSales / totalBills) : "0", "LAK", "ຍອດຂາຍສະເລ່ຍຕໍ່ບິນ", Icons.calculate)]),
          const SizedBox(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  height: 360, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: widget.colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: widget.colorScheme.outline)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("ແນວໂນ້ມຍອດຂາຍ (Sales Trend)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: widget.colorScheme.onSurface, fontFamily: 'sans-serif')), const SizedBox(height: 30),
                      Expanded(child: LineChart(LineChartData(
                            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: widget.colorScheme.outline, strokeWidth: 1, dashArray: [5, 5])),
                            titlesData: FlTitlesData(rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v,m){ if(v.toInt()>=0&&v.toInt()<dailyReport.length){int r=(dailyReport.length-1)-v.toInt(); if(dailyReport.length>14&&v.toInt()%(dailyReport.length~/7)!=0&&v.toInt()!=dailyReport.length-1) return const Text(''); return Padding(padding: const EdgeInsets.only(top: 10), child: Text(dailyReport[r]['date'].toString().split(' ').take(2).join(' '), style: TextStyle(fontSize: 11, color: widget.colorScheme.onSurfaceVariant, fontFamily: 'sans-serif'))); } return const Text('');})), leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50, getTitlesWidget: (v,m){ if(v==0) return const Text(''); return Padding(padding: const EdgeInsets.only(right: 10), child: Text("${(v/1000).toInt()}k", textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: widget.colorScheme.onSurfaceVariant, fontFamily: 'sans-serif')));}))),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [LineChartBarData(spots: List.generate(dailyReport.length, (index) { int r = (dailyReport.length - 1) - index; return FlSpot(index.toDouble(), r < dailyReport.length ? dailyReport[r]['revenue'] : 0.0); }), isCurved: false, color: widget.colorScheme.secondary, barWidth: 2, dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: widget.colorScheme.surface, strokeWidth: 2, strokeColor: widget.colorScheme.secondary)), belowBarData: BarAreaData(show: true, color: widget.colorScheme.secondary.withOpacity(0.1)))]
                      )))
                  ]),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 3,
                child: Container(
                  height: 360, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: widget.colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: widget.colorScheme.outline)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("5 ອັນດັບສິນຄ້າຂາຍດີ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: widget.colorScheme.onSurface, fontFamily: 'sans-serif')), const SizedBox(height: 20),
                      Expanded(child: topProducts.isEmpty ? Center(child: Text("ຍັງບໍ່ມີຂໍ້ມູນການຂາຍ", style: TextStyle(color: widget.colorScheme.onSurfaceVariant))) : ListView.builder(itemCount: topProducts.length, itemBuilder: (context, index) { return Padding(padding: const EdgeInsets.only(bottom: 18), child: Row(children: [Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: index == 0 ? widget.colorScheme.primary : index == 1 ? widget.colorScheme.secondary : index == 2 ? Colors.orange.shade400 : widget.colorScheme.onSurfaceVariant.withOpacity(0.3))), const SizedBox(width: 15), Expanded(child: Text(topProducts[index]['name'], style: TextStyle(color: widget.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'sans-serif'), overflow: TextOverflow.ellipsis)), Text("${NumberFormat("#,##0").format(topProducts[index]['revenue'])} LAK", style: TextStyle(color: widget.colorScheme.onSurface, fontSize: 14, fontFamily: 'sans-serif'))]));}))
                  ]),
                ),
              )
            ],
          ),
          const SizedBox(height: 30),
          Container(
            width: double.infinity, decoration: BoxDecoration(color: widget.colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: widget.colorScheme.outline)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: const EdgeInsets.all(20), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("ລາຍງານຍອດຂາຍລາຍວັນ (Daily Report)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: widget.colorScheme.onSurface, fontFamily: 'sans-serif')), Icon(Icons.table_view_outlined, color: widget.colorScheme.onSurfaceVariant)])),
                Divider(height: 1, color: widget.colorScheme.outline),
                Container(color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), child: Row(children: [Expanded(flex: 2, child: Text("ວັນທີ (Date)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: widget.colorScheme.onSurfaceVariant, fontFamily: 'sans-serif'))), Expanded(flex: 2, child: Text("ຍອດຂາຍ (Gross)", textAlign: TextAlign.right, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: widget.colorScheme.onSurfaceVariant, fontFamily: 'sans-serif'))), Expanded(flex: 2, child: Text("ຄືນເງິນ (Refund)", textAlign: TextAlign.right, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: widget.colorScheme.onSurfaceVariant, fontFamily: 'sans-serif'))), Expanded(flex: 2, child: Text("ຍອດຂາຍສຸດທິ (Net Sales)", textAlign: TextAlign.right, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: widget.colorScheme.onSurface, fontFamily: 'sans-serif')))])),
                Divider(height: 1, color: widget.colorScheme.outline),
                ...dailyReport.map((dayData) => Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: widget.colorScheme.outline, width: 0.5))), child: Row(children: [Expanded(flex: 2, child: Text(dayData['date'], style: TextStyle(fontSize: 14, color: widget.colorScheme.onSurface, fontFamily: 'sans-serif'))), Expanded(flex: 2, child: Text(fmt.format(dayData['revenue']), textAlign: TextAlign.right, style: TextStyle(fontSize: 14, color: widget.colorScheme.onSurface, fontFamily: 'sans-serif'))), Expanded(flex: 2, child: Text("0", textAlign: TextAlign.right, style: TextStyle(fontSize: 14, color: widget.colorScheme.onSurfaceVariant, fontFamily: 'sans-serif'))), Expanded(flex: 2, child: Text(fmt.format(dayData['revenue']), textAlign: TextAlign.right, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: widget.colorScheme.secondary, fontFamily: 'sans-serif')))]))).toList(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String unit, String subLabel, IconData icon, {bool isPrimary = false}) {
    return Expanded(child: Container(constraints: const BoxConstraints(minHeight: 120), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), decoration: BoxDecoration(color: widget.colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: isPrimary ? widget.colorScheme.secondary.withOpacity(0.5) : widget.colorScheme.outline, width: isPrimary ? 1.5 : 1)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isPrimary ? widget.colorScheme.secondary : widget.colorScheme.onSurfaceVariant, fontFamily: 'sans-serif')), Icon(icon, color: isPrimary ? widget.colorScheme.secondary : widget.colorScheme.onSurfaceVariant.withOpacity(0.5), size: 20)]), const SizedBox(height: 12), Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [Text(value, style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: widget.colorScheme.onSurface)), const SizedBox(width: 6), Text(unit, style: TextStyle(fontSize: 14, color: widget.colorScheme.onSurfaceVariant, fontFamily: 'sans-serif'))]), const SizedBox(height: 8), Text(subLabel, style: TextStyle(fontSize: 12, color: isPrimary ? widget.colorScheme.secondary : widget.colorScheme.onSurfaceVariant, fontFamily: 'sans-serif'))])));
  }
}

class SalesByProductView extends StatefulWidget {
  final ColorScheme colorScheme;
  const SalesByProductView({super.key, required this.colorScheme});
  @override
  State<SalesByProductView> createState() => _SalesByProductViewState();
}
class _SalesByProductViewState extends State<SalesByProductView> {
  bool isLoading = true; List<Map<String, dynamic>> allProductsData = [];
  DateTimeRange? selectedDateRange; String searchQuery = ""; String selectedCategory = "All";
  final List<String> categories = ["All", "Coffee", "Tea", "Dessert", "Other"];
  int sortColumnIndex = 3; bool isAscending = false;

  @override
  void initState() { super.initState(); fetchProductSales(); }

  Future<void> fetchProductSales() async {
    setState(() => isLoading = true);
    try {
      var response = await http.get(Uri.parse('$serverUrl/orders')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        List orders = json.decode(utf8.decode(response.bodyBytes)); Map<String, Map<String, dynamic>> productMap = {};
        for (var order in orders) {
          if (selectedDateRange != null && order['created_at'] != null) {
            try { DateTime orderDate = DateTime.parse(order['created_at']); DateTime start = DateTime(selectedDateRange!.start.year, selectedDateRange!.start.month, selectedDateRange!.start.day); DateTime end = DateTime(selectedDateRange!.end.year, selectedDateRange!.end.month, selectedDateRange!.end.day, 23, 59, 59); if (orderDate.isBefore(start) || orderDate.isAfter(end)) continue; } catch(e) {}
          }
          if (order['items'] != null) {
            for (var item in order['items']) {
              String pName = item['product_name'] ?? 'Unknown Item'; String pCat = "Coffee";
              if (pName.toLowerCase().contains("tea") || pName.toLowerCase().contains("matcha")) pCat = "Tea"; else if (pName.toLowerCase().contains("cake") || pName.toLowerCase().contains("croissant")) pCat = "Dessert"; else if (pName.toLowerCase().contains("cocoa")) pCat = "Other";
              int qty = item['quantity'] is int ? item['quantity'] : int.tryParse(item['quantity'].toString()) ?? 1; double price = double.tryParse(item['price_at_sale'].toString()) ?? 0.0; double rev = price * qty;
              if (productMap.containsKey(pName)) { productMap[pName]!['qty'] += qty; productMap[pName]!['rev'] += rev; } else { productMap[pName] = {'name': pName, 'cat': pCat, 'qty': qty, 'rev': rev}; }
            }
          }
        }
        allProductsData = productMap.values.toList();
      }
    } catch (e) { print("Error: $e"); } finally { setState(() => isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return Center(child: CircularProgressIndicator(color: widget.colorScheme.primary));
    List<Map<String, dynamic>> displayProducts = allProductsData.where((p) => (selectedCategory == "All" || p['cat'] == selectedCategory) && p['name'].toString().toLowerCase().contains(searchQuery.toLowerCase())).toList();
    displayProducts.sort((a, b) { var valA = sortColumnIndex == 2 ? a['qty'] : a['rev']; var valB = sortColumnIndex == 2 ? b['qty'] : b['rev']; return isAscending ? valA.compareTo(valB) : valB.compareTo(valA); });
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("ຍອດຂາຍຕາມສິນຄ້າ (Sales by Product)", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: widget.colorScheme.onSurface)), const SizedBox(height: 6), Text("ຂໍ້ມູນຍອດຂາຍ ແລະ ລາຍຮັບແຍກຕາມເມນູ", style: TextStyle(fontSize: 14, color: widget.colorScheme.onSurfaceVariant, fontFamily: 'sans-serif'))]),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(flex: 2, child: TextField(onChanged: (val) => setState(() => searchQuery = val), style: TextStyle(color: widget.colorScheme.onSurface, fontFamily: 'sans-serif', fontSize: 14), decoration: InputDecoration(hintText: "ຄົ້ນຫາຊື່ເມນູ... (Search menu)", hintStyle: TextStyle(color: widget.colorScheme.onSurfaceVariant), prefixIcon: Icon(Icons.search, color: widget.colorScheme.onSurfaceVariant), filled: true, fillColor: widget.colorScheme.surface, contentPadding: const EdgeInsets.symmetric(vertical: 0), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.colorScheme.outline), borderRadius: BorderRadius.circular(8)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.colorScheme.primary), borderRadius: BorderRadius.circular(8))))),
              const SizedBox(width: 16),
              Expanded(flex: 1, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: widget.colorScheme.surface, border: Border.all(color: widget.colorScheme.outline), borderRadius: BorderRadius.circular(8)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: selectedCategory, isExpanded: true, dropdownColor: widget.colorScheme.surface, icon: Icon(Icons.filter_list, color: widget.colorScheme.onSurfaceVariant), style: TextStyle(color: widget.colorScheme.onSurface, fontFamily: 'sans-serif', fontSize: 14), onChanged: (v) { if (v != null) setState(() => selectedCategory = v); }, items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c == "All" ? "ທຸກໝວດໝູ່" : c))).toList())))),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity, decoration: BoxDecoration(color: widget.colorScheme.surface, border: Border.all(color: widget.colorScheme.outline), borderRadius: BorderRadius.circular(10)), clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: widget.colorScheme.outline), 
                  child: DataTable(
                    sortColumnIndex: sortColumnIndex, sortAscending: isAscending, headingRowColor: MaterialStateProperty.resolveWith((states) => Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5)),
                    columns: [
                      DataColumn(label: Text("ສິນຄ້າ (Product)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: widget.colorScheme.onSurfaceVariant, fontFamily: 'sans-serif'))),
                      DataColumn(label: Text("ໝວດໝູ່ (Category)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: widget.colorScheme.onSurfaceVariant, fontFamily: 'sans-serif'))),
                      DataColumn(label: Text("ຈຳນວນທີ່ຂາຍ (Qty)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: widget.colorScheme.onSurfaceVariant, fontFamily: 'sans-serif')), numeric: true, onSort: (i,a) => setState((){sortColumnIndex=i; isAscending=a;})),
                      DataColumn(label: Text("ຍອດຂາຍລວມ (Total)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: widget.colorScheme.onSurfaceVariant, fontFamily: 'sans-serif')), numeric: true, onSort: (i,a) => setState((){sortColumnIndex=i; isAscending=a;})),
                    ],
                    rows: displayProducts.map((item) { int index = displayProducts.indexOf(item); return DataRow(color: MaterialStateProperty.resolveWith((states) => index % 2 == 0 ? Colors.transparent : Theme.of(context).scaffoldBackgroundColor.withOpacity(0.3)), cells: [DataCell(Text(item['name'], style: TextStyle(fontSize: 14, color: widget.colorScheme.onSurface, fontWeight: FontWeight.w500, fontFamily: 'sans-serif'))), DataCell(Text(item['cat'], style: TextStyle(fontSize: 14, color: widget.colorScheme.onSurfaceVariant, fontFamily: 'sans-serif'))), DataCell(Text("${item['qty']}", style: TextStyle(fontSize: 14, color: widget.colorScheme.onSurface, fontFamily: 'sans-serif'))), DataCell(Text(NumberFormat("#,##0").format(item['rev']), style: TextStyle(fontSize: 14, color: widget.colorScheme.secondary, fontWeight: FontWeight.bold, fontFamily: 'serif')))]); }).toList(),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class SalesByCategoryView extends StatefulWidget {
  final ColorScheme colorScheme;
  const SalesByCategoryView({super.key, required this.colorScheme});
  @override
  State<SalesByCategoryView> createState() => _SalesByCategoryViewState();
}
class _SalesByCategoryViewState extends State<SalesByCategoryView> {
  bool isLoading = true; List<Map<String, dynamic>> categoryData = []; double totalRevenue = 0;
  @override
  void initState() { super.initState(); fetchCategorySales(); }

  Future<void> fetchCategorySales() async {
    setState(() => isLoading = true);
    try {
      var response = await http.get(Uri.parse('$serverUrl/orders')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        List orders = json.decode(utf8.decode(response.bodyBytes));
        Map<String, Map<String, dynamic>> catMap = {'Coffee': {'cat': 'Coffee', 'qty': 0, 'rev': 0.0}, 'Tea': {'cat': 'Tea', 'qty': 0, 'rev': 0.0}, 'Dessert': {'cat': 'Dessert', 'qty': 0, 'rev': 0.0}, 'Other': {'cat': 'Other', 'qty': 0, 'rev': 0.0}};
        for (var order in orders) {
          if (order['items'] != null) {
            for (var item in order['items']) {
              String pName = item['product_name'] ?? ''; String cat = "Coffee"; 
              if (pName.toLowerCase().contains("tea") || pName.toLowerCase().contains("matcha")) cat = "Tea"; else if (pName.toLowerCase().contains("cake") || pName.toLowerCase().contains("croissant")) cat = "Dessert"; else if (pName.toLowerCase().contains("cocoa")) cat = "Other";
              int qty = item['quantity'] is int ? item['quantity'] : int.tryParse(item['quantity'].toString()) ?? 1; double price = double.tryParse(item['price_at_sale'].toString()) ?? 0.0;
              catMap[cat]!['qty'] += qty; catMap[cat]!['rev'] += (price * qty);
            }
          }
        }
        categoryData = catMap.values.where((e) => e['qty'] > 0).toList()..sort((a, b) => b['rev'].compareTo(a['rev']));
        totalRevenue = categoryData.fold(0.0, (sum, item) => sum + item['rev']);
      }
    } catch (e) { print(e); } finally { setState(() => isLoading = false); }
  }

  Color _getCategoryColor(String cat) {
    switch (cat) { case 'Coffee': return widget.colorScheme.primary; case 'Tea': return widget.colorScheme.secondary; case 'Dessert': return Colors.orange.shade400; default: return widget.colorScheme.onSurfaceVariant.withOpacity(0.5); }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return Center(child: CircularProgressIndicator(color: widget.colorScheme.primary));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("ຍອດຂາຍແຍກຕາມໝວດໝູ່", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: widget.colorScheme.onSurface, fontFamily: 'serif')), const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(30), decoration: BoxDecoration(color: widget.colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: widget.colorScheme.outline)),
            child: Row(
              children: [
                Expanded(flex: 2, child: SizedBox(height: 300, child: Stack(alignment: Alignment.center, children: [PieChart(PieChartData(sectionsSpace: 4, centerSpaceRadius: 90, sections: categoryData.map((data) => PieChartSectionData(color: _getCategoryColor(data['cat']), value: data['rev'], title: "${totalRevenue>0 ? ((data['rev']/totalRevenue)*100).toStringAsFixed(1) : 0}%", radius: 40, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'sans-serif'))).toList())), Column(mainAxisSize: MainAxisSize.min, children: [Text("ລາຍຮັບລວມ", style: TextStyle(fontSize: 14, color: widget.colorScheme.onSurfaceVariant, fontFamily: 'sans-serif')), Text(NumberFormat("#,##0").format(totalRevenue), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: widget.colorScheme.onSurface, fontFamily: 'serif')), Text("LAK", style: TextStyle(fontSize: 12, color: widget.colorScheme.onSurfaceVariant, fontFamily: 'sans-serif'))])]))), const SizedBox(width: 40),
                Expanded(flex: 3, child: Column(children: categoryData.map((data) => Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5), borderRadius: BorderRadius.circular(8), border: Border.all(color: widget.colorScheme.outline)), child: Row(children: [Container(width: 16, height: 16, decoration: BoxDecoration(color: _getCategoryColor(data['cat']), shape: BoxShape.circle)), const SizedBox(width: 16), Expanded(child: Text(data['cat'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: widget.colorScheme.onSurface, fontFamily: 'sans-serif'))), Text("${data['qty']} ແກ້ວ/ຊິ້ນ", style: TextStyle(fontSize: 14, color: widget.colorScheme.onSurfaceVariant, fontFamily: 'sans-serif')), const SizedBox(width: 24), SizedBox(width: 120, child: Text("${NumberFormat("#,##0").format(data['rev'])} LAK", textAlign: TextAlign.right, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: widget.colorScheme.secondary, fontFamily: 'serif')))]))).toList()))
              ],
            ),
          )
        ],
      ),
    );
  }
}