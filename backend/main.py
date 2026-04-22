from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List
import models, schemas, database
from database import SessionLocal, engine

models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="ILa HomeBar API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/")
def health_check():
    return {"status": "online", "server": "ILa HomeBar Server"}

# --- PRODUCTS ---
# 🚀 ลบ /api ออกตามคำสั่ง URL ในแอป
@app.get("/products", response_model=List[schemas.Product])
def get_products(db: Session = Depends(get_db)):
    return db.query(models.Product).filter(models.Product.is_active == True).all()

@app.post("/products", response_model=schemas.Product)
def create_product(product: schemas.ProductBase, db: Session = Depends(get_db)):
    db_item = models.Product(**product.dict())
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item

@app.put("/products/{id}", response_model=schemas.Product)
def update_product(id: int, product: schemas.ProductBase, db: Session = Depends(get_db)):
    db_item = db.query(models.Product).filter(models.Product.id == id).first()
    if not db_item: raise HTTPException(status_code=404)
    for k, v in product.dict().items(): setattr(db_item, k, v)
    db.commit()
    return db_item

@app.delete("/products/{id}")
def delete_product(id: int, db: Session = Depends(get_db)):
    db_item = db.query(models.Product).filter(models.Product.id == id).first()
    if db_item:
        db_item.is_active = False
        db.commit()
    return {"status": "deleted"}

# --- ORDERS ---
@app.post("/orders")
def create_order(order: schemas.OrderCreate, db: Session = Depends(get_db)):
    try:
        new_order = models.Order(
            total_amount=order.total_amount,
            payment_method=order.payment_method,
            loyalty_phone=order.loyalty_phone
        )
        db.add(new_order)
        db.flush()
        for item in order.items:
            db.add(models.OrderItem(order_id=new_order.id, **item.dict()))
        db.commit()
        return {"status": "success", "id": new_order.id}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/orders")
def get_orders(db: Session = Depends(get_db)):
    return db.query(models.Order).all()
