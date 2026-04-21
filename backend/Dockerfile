# 🐍 ใช้ Python 3.9 Slim เพื่อความเบา
FROM python:3.9-slim

# ตั้งค่า Working Directory
WORKDIR /app

# ติดตั้ง Dependencies ที่จำเป็นสำหรับ PostgreSQL
RUN apt-get update && apt-get install -y \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# ก๊อปปี้ไฟล์ Requirements และติดตั้ง
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ก๊อปปี้โค้ดทั้งหมดเข้า Container
COPY . .

# เปิดประตู Port 8000
EXPOSE 8000

# คำสั่งรัน Server
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
