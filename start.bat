@echo off
REM =====================================================
REM  Crew Quiz - lokal server
REM  Spotify kraever http://127.0.0.1 (ikke file://)
REM =====================================================
cd /d "%~dp0"

set PORT=8080
if not "%~1"=="" set PORT=%~1

echo.
echo   ============================
echo     CREW QUIZ - starter op
echo   ============================
echo.

if not exist "%~dp0index.html" (
  echo   FEJL: index.html blev ikke fundet i denne mappe:
  echo   %~dp0
  echo.
  echo   Laeg start.bat samme sted som index.html.
  echo.
  pause
  exit /b 1
)

REM --- Find en motor der RENT FAKTISK virker ---
REM  (vi koerer dem, i stedet for at bruge "where" - Windows har en
REM   falsk python.exe der blot aabner Microsoft Store)

set ENGINE=
set CMD=

py -3 -c "import http.server" >nul 2>nul
if not errorlevel 1 (
  set ENGINE=Python ^(py^)
  set CMD=py -3 -m http.server %PORT% --bind 127.0.0.1
  goto :run
)

python -c "import http.server" >nul 2>nul
if not errorlevel 1 (
  set ENGINE=Python
  set CMD=python -m http.server %PORT% --bind 127.0.0.1
  goto :run
)

python3 -c "import http.server" >nul 2>nul
if not errorlevel 1 (
  set ENGINE=Python3
  set CMD=python3 -m http.server %PORT% --bind 127.0.0.1
  goto :run
)

if exist "%~dp0serve.ps1" (
  set ENGINE=PowerShell ^(indbygget i Windows^)
  set CMD=powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0serve.ps1" -Port %PORT%
  goto :run
)

echo   FEJL: Fandt hverken Python eller serve.ps1.
echo   Soerg for at serve.ps1 ligger i samme mappe som denne fil,
echo   eller installer Python fra https://www.python.org/downloads/
echo   ^(saet flueben i "Add python.exe to PATH" under installationen^)
echo.
pause
exit /b 1

:run
echo   Motor:  %ENGINE%
echo   Adresse: http://127.0.0.1:%PORT%/
echo.
echo   Browseren aabner om et oejeblik.
echo   Lad DETTE vindue staa aabent mens I spiller.
echo.
echo   ---------------------------------------------
echo.

REM aabn browseren efter ca. 3 sek, saa serveren naar at starte
start "" /min cmd /c "ping -n 4 127.0.0.1 >nul & start """" http://127.0.0.1:%PORT%/"

%CMD%

echo.
echo   ---------------------------------------------
echo   Serveren er stoppet.
echo.
echo   Stod der "Address already in use" eller lignende, er port %PORT%
echo   optaget. Proev en anden port ved at koere i et cmd-vindue:
echo       start.bat 8090
echo   og aabn saa http://127.0.0.1:8090/
echo   ^(husk ogsaa at rette Redirect URI i Spotify-dashboardet^)
echo.
pause
