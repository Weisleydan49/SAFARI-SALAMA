@echo off
echo ==========================================
echo Safari Salama - Driver Native Kotlin App
echo ==========================================

echo.
echo [1/3] Launching Android Emulator in the background...
echo (If an emulator is already running, this will just resume it)
start "" "%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe" -avd "Medium_Phone_API_36"

echo.
echo [2/3] Waiting 15 seconds for emulator to initialize...
timeout /t 15 /nobreak >nul

echo.
echo [3/3] Compiling and Installing Driver App...
echo (This may take a few minutes on the first run as Gradle downloads dependencies)
cd d:\PROJECTS\SafariSalama\driver_app
call "..\mobile\android\gradlew.bat" installDebug

echo.
echo ==========================================
echo DONE! Check the emulator. The "Safari Salama Driver" application should be installed and running.
echo ==========================================
pause
