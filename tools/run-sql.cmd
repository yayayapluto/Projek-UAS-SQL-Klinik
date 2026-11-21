@echo off
rem =====================================================================
rem tools/run-sql.cmd
rem Pembungkus untuk CMD dan PowerShell. Mencari Git Bash atau MSYS2,
rem lalu meneruskan semua argumen ke tools/run-sql.sh.
rem =====================================================================
setlocal EnableExtensions
set "HERE=%~dp0"
set "BASH_EXE="

for %%B in (
  "%ProgramFiles%\Git\bin\bash.exe"
  "%ProgramFiles%\Git\usr\bin\bash.exe"
  "%ProgramFiles(x86)%\Git\bin\bash.exe"
  "%LOCALAPPDATA%\Programs\Git\bin\bash.exe"
  "C:\msys64\usr\bin\bash.exe"
  "%USERPROFILE%\scoop\apps\git\current\bin\bash.exe"
) do (
  if not defined BASH_EXE if exist "%%~B" set "BASH_EXE=%%~B"
)

if not defined BASH_EXE (
  bash -c "exit 0" >nul 2>nul
  if not errorlevel 1 set "BASH_EXE=bash"
)

if not defined BASH_EXE (
  echo GAGAL: Git Bash atau MSYS2 tidak ditemukan.
  echo Pasang Git untuk Windows, lalu buka terminal baru.
  echo Jika bash ada di lokasi lain, jalankan langsung:
  echo   ^<path-bash^> tools/run-sql.sh 02
  exit /b 1
)

"%BASH_EXE%" "%HERE%run-sql.sh" %*
exit /b %ERRORLEVEL%