@echo off
title NEXTDEBUT_PYTHON_CONSOLE
cd /d "C:\Users\KOSMO\Desktop\NEXTDEBUT\python-ml"
set "PATH=C:\python\Scripts;%PATH%"
echo [NEXTDEBUT] Python ML server starting...
type nul > "C:\Users\KOSMO\Desktop\NEXTDEBUT\logs\python-ml.log"
call py -3 -m uvicorn app:app --host 127.0.0.1 --port 8000 >> "C:\Users\KOSMO\Desktop\NEXTDEBUT\logs\python-ml.log" 2>&1
