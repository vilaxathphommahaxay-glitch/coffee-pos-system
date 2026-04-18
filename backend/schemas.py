from pydantic import BaseModel
from typing import List, Optional
from decimal import Decimal
from datetime import datetime

# --- ສ່ວນຂອງ Product (ສິນຄ້າ) ---
class ProductBase(BaseModel):
    name: str
    category: str
    price: Decimal
    image_url: Optional[str] = None
    is_active: bool = True

class ProductCreate(ProductBase):
    pass

class Product(ProductBase):
    id: int
    class Config:
        from_attributes = True

# --- ສ່ວນຂອງ Order (ການຂາຍ) ---
class OrderItemBase(BaseModel):
    product_id: int
    quantity: int
    price_at_sale: Decimal

class OrderCreate(BaseModel):
    items: List[OrderItemBase]
    payment_method: str
    employee_id: int
    total_amount: Decimal

class Order(OrderCreate):
    id: int
    created_at: datetime
    class Config:
        from_attributes = True