from main import Base, engine
print("⏳ กำลังล้างฐานข้อมูล...")
Base.metadata.drop_all(bind=engine) # ลบทุกตาราง
Base.metadata.create_all(bind=engine) # สร้างใหม่พร้อมช่องเก็บข้อมูลใหม่
print("✅ เรียบร้อย! ฐานข้อมูลใหม่พร้อมใช้งานแล้ว")
