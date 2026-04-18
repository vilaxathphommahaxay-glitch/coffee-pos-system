from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import requests

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# กุญแจ Supabase ของคุณ (ผมใส่ให้เรียบร้อยแล้วครับ ลุยได้เลย)
SUPABASE_URL = "https://nmpaixqbespnkrvturnz.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5tcGFpeHFiZXNwbmtydnR1cm56Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ5NjgwMTUsImV4cCI6MjA5MDU0NDAxNX0.7WxYbJIKxyuge6Oyz6pz-jnS9MYa1No8c4wFFmke5Os"

def get_headers():
    return {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "return=representation"
    }

class Order(BaseModel):
    items: list
    total_price: float

# ==========================================
# 📦 ดึงหมวดหมู่ (ดักไว้ทั้ง 2 ทางเลยเผื่อแอปเรียกผิด)
# ==========================================
@app.get("/categories")
@app.get("/api/categories")
def get_categories():
    try:
        url = f"{SUPABASE_URL}/rest/v1/categories?select=*"
        res = requests.get(url, headers=get_headers())
        res.raise_for_status()
        return res.json()
    except Exception as e:
        return []

# ==========================================
# ☕ ดึงเมนูสินค้า (ดักไว้ทั้ง 2 ทางเช่นกัน!)
# ==========================================
@app.get("/products")
@app.get("/api/products")
def get_products():
    try:
        url = f"{SUPABASE_URL}/rest/v1/products?select=*"
        res = requests.get(url, headers=get_headers())
        res.raise_for_status()
        return res.json()
    except Exception as e:
        return []

# ==========================================
# ☁️ ส่งออเดอร์ขึ้น Cloud
# ==========================================
@app.post("/orders")
@app.post("/api/orders")
async def create_order(order: Order):
    try:
        url = f"{SUPABASE_URL}/rest/v1/orders"
        payload = {"items": order.items, "total_price": order.total_price}
        
        res = requests.post(url, headers=get_headers(), json=payload)
        res.raise_for_status() 
        return {"status": "success", "message": "ออเดอร์บันทึกขึ้นคลาวด์แล้ว!", "data": res.json()}
    except Exception as e:
        return {"status": "error", "message": str(e)}

# 👇 ประตูหน้าบ้าน เอาไว้รับแขกและเอาใจยาม Render 👇
@app.get("/")
def read_root():
    return {"message": "Hello Render! Sumday POS is awake and healthy! 🟢"}