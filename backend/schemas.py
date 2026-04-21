from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

# --- สินค้า (Product) ---
class ProductBase(BaseModel):
    name: str
    category: str
    price: float
    stock: int
    image_url: Optional[str] = None

class Product(ProductBase):
    id: int
    is_active: bool

    class Config:
        from_attributes = True

# --- รายการในออเดอร์ (Order Item) ---
class OrderItemBase(BaseModel):
    product_id: int
    quantity: int
    price_at_sale: float
    sweetness: Optional[str] = ""
    item_type: Optional[str] = ""
    note: Optional[str] = ""

class OrderItem(OrderItemBase):
    id: int
    order_id: int

    class Config:
        from_attributes = True

# --- ออเดอร์ (Order) ---
class OrderBase(BaseModel):
    total_amount: float
    payment_method: str
    employee_id: Optional[int] = None

class OrderCreate(OrderBase):
    items: List[OrderItemBase]

class Order(OrderBase):
    id: int
    created_at: datetime
    sync_status: str
    items: List[OrderItem]

    class Config:
        from_attributes = True
