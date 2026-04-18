from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Float, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base

# 1. ຕາຕະລາງສິນຄ້າ (Product Table)
class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    category = Column(String)
    price = Column(Float) # ใช้ Float เพื่อความง่ายในการคำนวณกับ main.py
    cost = Column(Float, default=0) # ต้นทุน (เผื่อทำกำไรขาดทุน)
    image_url = Column(String, nullable=True) # รูปภาพ
    is_active = Column(Boolean, default=True)
    stock = Column(Integer, default=0) # ⭐ จำนวนสต็อก (สำคัญมาก)


# 2. ຕາຕະລາງອໍເດີ (Order Table)
class Order(Base):
    __tablename__ = "orders"

    id = Column(Integer, primary_key=True, index=True)
    total_amount = Column(Float)
    payment_method = Column(String) # Cash, QR_ONEPAY
    
    # ทำให้ employee_id เป็น nullable (ว่างได้) เผื่อยังไม่ได้ทำระบบ Login
    employee_id = Column(Integer, ForeignKey("employees.id"), nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    sync_status = Column(String, default="synced")

    # เชื่มต่อกับ OrderItem
    items = relationship("OrderItem", back_populates="order")


# 3. ຕາຕະລາງລາຍການໃນອໍເດີ (Order Items)
class OrderItem(Base):
    __tablename__ = "order_items"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"))
    product_id = Column(Integer, ForeignKey("products.id"))
    quantity = Column(Integer)
    price_at_sale = Column(Float)

    # ⭐ เพิ่ม 3 ช่องนี้ เพื่อให้รองรับฟีเจอร์ล่าสุดที่เราทำ ⭐
    sweetness = Column(String, default="") # ระดับความหวาน
    item_type = Column(String, default="") # ร้อน/เย็น/ปั่น
    note = Column(String, default="")      # หมายเหตุ

    order = relationship("Order", back_populates="items")
    product = relationship("Product")


# 4. ຕາຕະລາງພະນັກງານ (Employee Table)
class Employee(Base):
    __tablename__ = "employees"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    password_hash = Column(String)
    role = Column(String, default="cashier")