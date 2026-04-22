import json
import sqlite3 # หรือเปลี่ยนเป็น connection ของ MariaDB ตามที่ setup ไว้
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import models # อ้างอิงไฟล์ models.py ที่เรามี

# เชื่อมต่อกับ MariaDB บนเครื่อง Dell
# แก้ไข URL ให้ตรงกับที่คุณใช้ใน database.py
SQLALCHEMY_DATABASE_URL = "sqlite:///./sql_app.db" # ตัวอย่างเป็น sqlite ให้กัปตันแก้เป็น MariaDB ตาม database.py นะครับ
engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def seed_data():
    db = SessionLocal()
    
    # เมนูแนะนำสำหรับ ILa HomeBar
    menu_items = [
        {"name": "Espresso", "category": "Coffee", "price": 15000, "image_url": "https://images.unsplash.com/photo-1510591509098-f4fdc6d0ff04?q=80&w=500", "stock": 1000},
        {"name": "Americano", "category": "Coffee", "price": 18000, "image_url": "https://images.unsplash.com/photo-1551030173-122ad3d81ca7?q=80&w=500", "stock": 1000},
        {"name": "ILa Latte", "category": "Coffee", "price": 22000, "image_url": "https://images.unsplash.com/photo-1536939459926-301728717817?q=80&w=500", "stock": 500},
        {"name": "Dirty Coffee", "category": "Coffee", "price": 25000, "image_url": "https://images.unsplash.com/photo-1594631252845-29fc4cc8cde9?q=80&w=500", "stock": 300},
        {"name": "Slow Bar Drip", "category": "Coffee", "price": 35000, "image_url": "https://images.unsplash.com/photo-1544787210-2213dfb4ad53?q=80&w=500", "stock": 200},
        {"name": "Matcha Latte", "category": "Tea", "price": 28000, "image_url": "https://images.unsplash.com/photo-1515823064-d6e0c04616a7?q=80&w=500", "stock": 400},
        {"name": "Craft Chocolate", "category": "Other", "price": 25000, "image_url": "https://images.unsplash.com/photo-1544415707-19bb7507ecc7?q=80&w=500", "stock": 300},
    ]

    print("--- Seeding ILa HomeBar Menu ---")
    for item in menu_items:
        # ตรวจสอบว่ามีเมนูนี้อยู่หรือยัง
        existing = db.query(models.Product).filter(models.Product.name == item['name']).first()
        if not existing:
            new_item = models.Product(
                name=item['name'],
                category=item['category'],
                price=item['price'],
                image_url=item['image_url'],
                stock=item['stock'],
                is_active=True
            )
            db.add(new_item)
            print(f"Added: {item['name']}")
    
    db.commit()
    db.close()
    print("--- Seeding Complete! ---")

if __name__ == "__main__":
    seed_data()
