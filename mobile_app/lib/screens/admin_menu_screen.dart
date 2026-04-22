import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/models.dart';

class AdminMenuScreen extends StatefulWidget {
  final List<ProductModel> initialProducts;
  const AdminMenuScreen({super.key, required this.initialProducts});

  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> {
  late List<ProductModel> localProducts;
  final String serverUrl = "http://100.107.25.103:8000";

  @override
  void initState() {
    super.initState();
    localProducts = List.from(widget.initialProducts);
  }

  Future<void> _saveProductToServer(Map<String, dynamic> productData, bool isEdit) async {
    try {
      final url = isEdit 
          ? Uri.parse('$serverUrl/products/${productData['id']}') 
          : Uri.parse('$serverUrl/products');
      
      final response = await (isEdit 
          ? http.put(url, headers: {"Content-Type": "application/json"}, body: json.encode(productData))
          : http.post(url, headers: {"Content-Type": "application/json"}, body: json.encode(productData)));

      if (response.statusCode == 200) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Saved to Server Successfully!")));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Server Error: ${response.statusCode}")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("⚠️ Offline Mode: Saved locally only. ($e)")));
    }
  }

  void _showProductForm({ProductModel? product}) {
    bool isEdit = product != null;
    final nameCtrl = TextEditingController(text: isEdit ? product.name : "");
    final priceCtrl = TextEditingController(text: isEdit ? product.price.toString() : "");
    final imgCtrl = TextEditingController(text: isEdit ? product.image : "");
    String category = isEdit ? product.category : "Coffee";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isEdit ? "Edit Product" : "Add Product", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Price (LAK)")),
            TextField(controller: imgCtrl, decoration: const InputDecoration(labelText: "Image URL")),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: category,
              items: ["Coffee", "Tea", "Dessert", "Other"].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => category = val!,
              decoration: const InputDecoration(labelText: "Category"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              onPressed: () async {
                final productMap = {
                  if (isEdit) "id": product.id,
                  "name": nameCtrl.text,
                  "price": double.parse(priceCtrl.text),
                  "category": category,
                  "image_url": imgCtrl.text,
                  "stock": isEdit ? product.stock : 100,
                  "is_active": true,
                };

                // 🚀 ยิงขึ้น Server ทันที
                await _saveProductToServer(productMap, isEdit);

                setState(() {
                  if (isEdit) {
                    int idx = localProducts.indexWhere((p) => p.id == product.id);
                    localProducts[idx] = ProductModel(
                      id: product.id, name: nameCtrl.text, price: double.parse(priceCtrl.text),
                      category: category, image: imgCtrl.text, stock: product.stock,
                    );
                  } else {
                    // Note: ID ตัวจริงจะมาจาก Server หลังจากรีเฟรชหน้าหลัก
                    localProducts.add(ProductModel(
                      id: localProducts.length + 1, name: nameCtrl.text, price: double.parse(priceCtrl.text),
                      category: category, image: imgCtrl.text, stock: 100,
                    ));
                  }
                });
                if (mounted) Navigator.pop(context);
              },
              child: const Text("SAVE"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Menu Management")),
      body: ListView.separated(
        itemCount: localProducts.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final p = localProducts[index];
          return ListTile(
            leading: CircleAvatar(backgroundImage: p.image.isNotEmpty ? NetworkImage(p.image) : null, child: p.image.isEmpty ? const Icon(Icons.coffee) : null),
            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${p.price} LAK | ${p.category}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showProductForm(product: p)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {
                  // TODO: เพิ่มการลบใน Backend ด้วย
                  setState(() => localProducts.removeAt(index));
                }),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
