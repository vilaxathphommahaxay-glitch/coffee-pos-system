
import requests
import json

# 🌐 ชี้ไปที่ Dell Home Server (ผ่าน Localhost สำหรับการ Seed ในเครื่อง)
BASE_URL = "http://localhost:8080" 
# หรือใช้ "http://100.107.25.103:8080" ถ้าส่งจากเครื่องอื่นผ่าน Tailscale

menus = [
    # --- ☕ COFFEE (Speed Bar) ---
    {"name": "Espresso (Hot)", "category": "Coffee", "price": 15000, "stock": 999, "image_url": ""},
    {"name": "Americano (Iced)", "category": "Coffee", "price": 18000, "stock": 999, "image_url": ""},
    {"name": "Latte (Iced)", "category": "Coffee", "price": 22000, "stock": 999, "image_url": ""},
    {"name": "Cappuccino (Iced)", "category": "Coffee", "price": 22000, "stock": 999, "image_url": ""},
    {"name": "Flat White (Hot)", "category": "Coffee", "price": 20000, "stock": 999, "image_url": ""},
    {"name": "Dirty Coffee", "category": "Coffee", "price": 28000, "stock": 100, "image_url": ""},
    {"name": "Caramel Macchiato", "category": "Coffee", "price": 30000, "stock": 999, "image_url": ""},
    {"name": "Mocha (Iced)", "category": "Coffee", "price": 25000, "stock": 999, "image_url": ""},
    
    # --- 🍃 TEA & NON-COFFEE ---
    {"name": "Premium Matcha Latte", "category": "Tea", "price": 35000, "stock": 500, "image_url": ""},
    {"name": "Thai Milk Tea (ILa Style)", "category": "Tea", "price": 20000, "stock": 999, "image_url": ""},
    {"name": "Hojicha Latte", "category": "Tea", "price": 32000, "stock": 500, "image_url": ""},
    {"name": "Earl Grey Lemon Tea", "category": "Tea", "price": 25000, "stock": 999, "image_url": ""},
    {"name": "Cocoa Mint", "category": "Other", "price": 28000, "stock": 999, "image_url": ""},
    
    # --- 🥤 REFRESHING (Soda) ---
    {"name": "Honey Lemon Soda", "category": "Other", "price": 25000, "stock": 999, "image_url": ""},
    {"name": "Peach Tea Soda", "category": "Other", "price": 28000, "stock": 999, "image_url": ""},
    {"name": "Black Orange (Coffee + Orange)", "category": "Coffee", "price": 32000, "stock": 999, "image_url": ""},

    # --- 🥐 BAKERY ---
    {"name": "Butter Croissant", "category": "Dessert", "price": 18000, "stock": 20, "image_url": ""},
    {"name": "Almond Croissant", "category": "Dessert", "price": 25000, "stock": 15, "image_url": ""},
    {"name": "Blueberry Cheesecake", "category": "Dessert", "price": 35000, "stock": 10, "image_url": ""},
    {"name": "Chocolate Brownie", "category": "Dessert", "price": 15000, "stock": 25, "image_url": ""},
]

def seed_data():
    print(f"🚀 Starting to seed expert menu to {BASE_URL}...")
    success_count = 0
    for menu in menus:
        # 🧪 ลองยิง 2 Path เผื่อว่า Server ยังใช้โค้ดเก่า
        paths = ["/products", "/api/products"] 
        for path in paths:
            try:
                response = requests.post(f"{BASE_URL}{path}", json=menu)
                if response.status_code == 200:
                    print(f"✅ Added: {menu['name']} (via {path})")
                    success_count += 1
                    break # ถ้าสำเร็จแล้วไม่ต้องลอง Path อื่น
                else:
                    if path == paths[-1]: # ถ้าลองครบทุก Path แล้วยังไม่ได้
                        print(f"❌ Failed: {menu['name']} (Last Status: {response.status_code})")
            except Exception as e:
                print(f"⚠️ Error connecting to server: {e}")
                return
    
    print(f"\n✨ Completed! Successfully added {success_count}/{len(menus)} items.")

if __name__ == "__main__":
    seed_data()
