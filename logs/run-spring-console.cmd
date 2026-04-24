@echo off
title NEXTDEBUT_SPRING_CONSOLE
cd /d "C:\Users\KOSMO\Desktop\NEXTDEBUT"
echo [NEXTDEBUT] Spring server starting...
set "JAVA_HOME=C:\Users\KOSMO\Desktop\NEXTDEBUT\runtime\jre\jdk-21.0.10+7"
set "PATH=C:\Users\KOSMO\Desktop\NEXTDEBUT\runtime\jre\jdk-21.0.10+7\bin;%PATH%"
type nul > "C:\Users\KOSMO\Desktop\NEXTDEBUT\logs\spring.log"
call gradlew.bat --no-daemon bootRun >> "C:\Users\KOSMO\Desktop\NEXTDEBUT\logs\spring.log" 2>&1
