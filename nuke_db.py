import os
import sys

# เพิ่ม path ให้หาไฟล์ backend เจอ
sys.path.append(os.getcwd())

# ชื่อไฟล์ฐานข้อมูล
db_name = "sql_app.db"

# 1. ตามล่าหาไฟล์และลบทิ้ง
if os.path.exists(db_name):
    try:
        os.remove(db_name)
        print(f"✅ ลบไฟล์ {db_name} เรียบร้อยแล้ว! (Cleaned)")
    except Exception as e:
        print(f"❌ ลบไม่ได้! (ติด Permission): {e}")
        print("👉 กรุณาปิด Terminal ที่รัน Server อยู่ แล้วลองใหม่")
else:
    print(f"⚠️ ไม่เจอไฟล์ {db_name} (แปลว่าสะอาดอยู่แล้ว หรือไฟล์ไปอยู่ที่อื่น)")

# 2. ลองหาในโฟลเดอร์ backend เผื่อมันไปแอบอยู่นั่น
backend_db = os.path.join("backend", "sql_app.db")
if os.path.exists(backend_db):
    try:
        os.remove(backend_db)
        print(f"✅ เจอไฟล์แอบใน backend... ลบเรียบร้อย!")
    except:
        pass

# 3. สร้างตารางใหม่ทันที
print("⏳ กำลังสร้างฐานข้อมูลใหม่ที่มีช่อง Stock...")
try:
    from backend.database import engine
    from backend.models import Base
    Base.metadata.create_all(bind=engine)
    print("🎉 สร้างฐานข้อมูลใหม่สำเร็จ! พร้อมใช้งานแล้ว")
except Exception as e:
    print(f"❌ สร้างตารางไม่สำเร็จ: {e}")