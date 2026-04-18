from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# 1. ກຳນົດ URL ສຳລັບຕິດຕໍ່ Database
# ຮູບແບບ: postgresql://username:password@localhost/dbname
# ⚠️ ຢ່າລືມປ່ຽນ 'your_password' ເປັນລະຫັດຜ່ານທີ່ເຈົ້າຕັ້ງໄວ້!
SQLALCHEMY_DATABASE_URL = "postgresql://postgres:admin@localhost/coffee_pos_db"

# 2. ສ້າງ Engine (ຕົວຂັບເຄື່ອນການເຊື່ອມຕໍ່)
engine = create_engine(SQLALCHEMY_DATABASE_URL)

# 3. ສ້າງ SessionLocal (ຫ້ອງເຮັດວຽກສຳລັບຕິດຕໍ່ຖານຂໍ້ມູນ)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# 4. ສ້າງ Base Class (ແມ່ແບບສຳລັບສ້າງຕາຕະລາງ)
Base = declarative_base()

# 5. ຟັງຊັນສຳລັບດຶງ Database Session (Dependency)
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()