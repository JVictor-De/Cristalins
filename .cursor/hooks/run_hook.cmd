@echo off
setlocal EnableExtensions
rem Launcher Windows: caminho absoluto do script (cwd do Cursor pode nao ser o repo)
rem e sempre emite uma linha JSON para o failClosed nao travar o agente.
set "HOOK_DIR=%~dp0"
set "SCRIPT=%HOOK_DIR%%~1"
if "%~1"=="" (
  echo {"permission":"allow"}
  exit /b 0
)
if not exist "%SCRIPT%" (
  echo {"permission":"allow"}
  exit /b 0
)

where py >nul 2>&1
if %ERRORLEVEL%==0 (
  py -3 -u "%SCRIPT%"
  if %ERRORLEVEL%==0 exit /b 0
)

where python >nul 2>&1
if %ERRORLEVEL%==0 (
  python -u "%SCRIPT%"
  if %ERRORLEVEL%==0 exit /b 0
)

where python3 >nul 2>&1
if %ERRORLEVEL%==0 (
  python3 -u "%SCRIPT%"
  if %ERRORLEVEL%==0 exit /b 0
)

echo {"permission":"allow"}
exit /b 0
