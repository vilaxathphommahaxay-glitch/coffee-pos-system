@echo off
title Sumday POS Server
color 0A

echo ===================================================
echo     Starting Sumday POS for iPhone 12...
echo ===================================================
echo.

echo [1/2] Starting Backend Server (Python)...
:: เปิดหน้าต่างใหม่เพื่อรัน Backend
start "Backend API (DO NOT CLOSE)" cmd /c "python -m uvicorn backend.main:app --host 0.0.0.0 --port 8000"

:: รอ 3 วินาทีให้ Backend รันเสร็จก่อน
timeout /t 3 >nul

echo [2/2] Starting Frontend Server (Flutter Web)...
:: เข้าไปที่โฟลเดอร์ mobile_app แล้วรัน Frontend
cd mobile_app
start "Frontend Web (DO NOT CLOSE)" cmd /c "flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080"

echo.
echo ===================================================
echo    ✅ SYSTEM IS READY! (ระบบพร้อมใช้งานแล้ว)
echo    📱 ให้หยิบ iPhone 12 ขึ้นมาแล้วกดเข้าแอปได้เลยครับ
echo    🌐 URL: http://192.168.1.6:8080
echo ===================================================
echo.
echo *** ห้ามปิดหน้าต่างสีดำนี้เด็ดขาด (ย่อเก็บไว้ได้) ***
pause