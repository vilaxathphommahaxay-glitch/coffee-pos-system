from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List
import models, schemas, database
from database import SessionLocal, engine

# Create Tables in PostgreSQL
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="ILa HomeBar API")

# ✅ CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# DB Session Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/")
def read_root():
    return {"message": "☕ ILa HomeBar Server is Online!", "status": "healthy"}

# --- 📦 PRODUCTS & CATEGORIES ---

@app.get("/products", response_model=List[schemas.Product])
def get_products(db: Session = Depends(get_db)):
    return db.query(models.Product).filter(models.Product.is_active == True).all()

@app.get("/categories")
def get_categories(db: Session = Depends(get_db)):
    categories = db.query(models.Product.category).distinct().all()
    return [c[0] for c in categories]

# --- 🧾 ORDERS ---

@app.post("/orders")
def create_order(order: schemas.OrderCreate, db: Session = Depends(get_db)):
    try:
        # 1. Create Order
        new_order = models.Order(
            total_amount=order.total_amount,
            payment_method=order.payment_method,
            employee_id=order.employee_id,
            sync_status="synced"
        )
        db.add(new_order)
        db.flush()

        # 2. Add Items & Update Stock
        for item in order.items:
            order_item = models.OrderItem(
                order_id=new_order.id,
                product_id=item.product_id,
                quantity=item.quantity,
                price_at_sale=item.price_at_sale,
                sweetness=item.sweetness,
                item_type=item.item_type,
                note=item.note
            )
            db.add(order_item)

            # Update Stock logic
            product = db.query(models.Product).filter(models.Product.id == item.product_id).first()
            if product and product.stock >= item.quantity:
                product.stock -= item.quantity

        db.commit()
        db.refresh(new_order)
        return {"status": "success", "order_id": new_order.id}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Order creation failed: {str(e)}")

@app.get("/orders")
def get_order_history(limit: int = 50, db: Session = Depends(get_db)):
    return db.query(models.Order).order_by(models.Order.created_at.desc()).limit(limit).all()

@app.delete("/orders/{order_id}")
def refund_order(order_id: int, db: Session = Depends(get_db)):
    order = db.query(models.Order).filter(models.Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order ID not found")
    
    # Restock products
    for item in order.items:
        product = db.query(models.Product).filter(models.Product.id == item.product_id).first()
        if product:
            product.stock += item.quantity
            
    db.delete(order)
    db.commit()
    return {"status": "success", "message": "Order refunded and stock restored"}
