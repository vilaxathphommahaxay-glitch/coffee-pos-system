import requests
import json

# URL ของ Backend
API_URL = "http://192.168.1.10:8000/products"

# รายการเมนู Café Amazon Style (ใส่ Stock = 50)
amazon_menu = [
    # --- Coffee ---
    {"name": "Iced Espresso (Amazon)", "category": "Coffee", "price": 28000, "is_active": True, "stock": 50},
    {"name": "Iced Black Coffee", "category": "Coffee", "price": 25000, "is_active": True, "stock": 50},
    {"name": "Iced Black Coffee Honey", "category": "Coffee", "price": 28000, "is_active": True, "stock": 50},
    {"name": "Iced Cappuccino", "category": "Coffee", "price": 28000, "is_active": True, "stock": 50},
    {"name": "Iced Latte", "category": "Coffee", "price": 28000, "is_active": True, "stock": 50},
    {"name": "Iced Mocha", "category": "Coffee", "price": 30000, "is_active": True, "stock": 50},
    {"name": "White Chocolate Macchiato", "category": "Coffee", "price": 32000, "is_active": True, "stock": 50},

    # --- Tea & Milk ---
    {"name": "Iced Green Tea Latte", "category": "Tea", "price": 28000, "is_active": True, "stock": 50},
    {"name": "Iced Thai Tea", "category": "Tea", "price": 28000, "is_active": True, "stock": 50},
    {"name": "Iced Lemon Tea", "category": "Tea", "price": 25000, "is_active": True, "stock": 50},
    {"name": "Iced Chocolate", "category": "Other", "price": 28000, "is_active": True, "stock": 50},
    {"name": "Fresh Milk Tea", "category": "Tea", "price": 25000, "is_active": True, "stock": 50},
    {"name": "Iced Lychee Juice", "category": "Other", "price": 25000, "is_active": True, "stock": 50},
    {"name": "Strawberry Cheesecake Frappe", "category": "Dessert", "price": 45000, "is_active": True, "stock": 50},
]

print("⏳ กำลังเพิ่มสินค้าและสต็อก (50 ชิ้น)...")

for item in amazon_menu:
    try:
        response = requests.post(API_URL, json=item)
        if response.status_code == 200:
            print(f"✅ เพิ่มสำเร็จ: {item['name']} (Stock: 50)")
        else:
            print(f"❌ เพิ่มไม่สำเร็จ: {item['name']} (Error: {response.status_code})")
    except Exception as e:
        print(f"❌ เชื่อมต่อ Server ไม่ได้: {e}")

print("\n🎉 เรียบร้อย! ตอนนี้สินค้ามีของในสต็อกแล้ว")