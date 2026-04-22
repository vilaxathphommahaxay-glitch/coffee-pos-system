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
  final String type; // Hot / Iced
  final String sweet; // 0%, 25%, 50%, 100%
  final String note;
  final String category;
  final String bean; // House Blend / Single Origin
  final String milk; // Normal / Oat / Almond
  final String brewMethod; // Espresso / Flair / V60 / Aeropress

  CartItem({
    required this.productId, 
    required this.name, 
    required this.price, 
    required this.qty, 
    required this.type, 
    required this.sweet, 
    required this.note, 
    required this.category,
    this.bean = "House Blend",
    this.milk = "Normal",
    this.brewMethod = "Espresso"
  });

  CartItem copyWith({int? qty}) {
    return CartItem(
      productId: productId,
      name: name,
      price: price,
      qty: qty ?? this.qty,
      type: type,
      sweet: sweet,
      note: note,
      category: category,
      bean: bean,
      milk: milk,
      brewMethod: brewMethod,
    );
  }

  Map<String, dynamic> toJson() => {
    "product_id": productId, 
    "product_name": name, 
    "quantity": qty, 
    "price_at_sale": price,
    "sweetness": sweet, 
    "item_type": type, 
    "note": note, 
    "category": category,
    "bean": bean,
    "milk": milk,
    "brew_method": brewMethod
  };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['product_id'], 
      name: json['product_name'], 
      price: (json['price_at_sale'] as num).toDouble(),
      qty: json['quantity'], 
      type: json['item_type'], 
      sweet: json['sweetness'], 
      note: json['note'], 
      category: json['category'] ?? '',
      bean: json['bean'] ?? "House Blend",
      milk: json['milk'] ?? "Normal",
      brewMethod: json['brew_method'] ?? "Espresso"
    );
  }
}
