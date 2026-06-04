@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:main_menu
cls
echo ====================================================================
echo             Transparent Background Portable
echo ====================================================================
echo 1. Start GUI (transparent-background-gui)
echo 2. Process video: Green screen (replace background with green)
echo 3. Process video: Mask (foreground/background mask)
echo 4. Install / Re-install Transparent Background
echo 5. Update Transparent Background
echo ====================================================================
echo By NeiroVlad, 2026
echo ====================================================================
set /p choice=Choose action 1-5: 
if "%choice%"=="1" goto start_gui
if "%choice%"=="2" goto process_green
if "%choice%"=="3" goto process_mask
if "%choice%"=="4" goto install_tb
if "%choice%"=="5" goto update_tb
echo Wrong choice. Please, try again.
pause
goto main_menu

:start_gui
setlocal
set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "VENV=%ROOT%\.venv"
set "MODELS=%ROOT%\models"
set "CACHE=%ROOT%\cache"

REM Local cache for portability
set "UV_CACHE_DIR=%CACHE%\uv"
set "PIP_CACHE_DIR=%CACHE%\pip"
set "UV_LINK_MODE=copy"

REM Models folder inside project
set "TRANSPARENT_BACKGROUND_FILE_PATH=%MODELS%"

echo [INFO] Starting Transparent Background GUI...
echo [INFO] Model files will be stored in: %MODELS%
echo [INFO] UV cache: %UV_CACHE_DIR%
echo [INFO] Close the GUI window to return to menu.

set "PATH=%VENV%\Scripts;%VENV%\Library\bin;%PATH%"

start /wait "" "%VENV%\Scripts\transparent-background-gui.exe"

echo [INFO] GUI closed.
pause
endlocal
goto main_menu

:process_green
call :process_video green
goto main_menu

:process_mask
call :process_video map
goto main_menu

:process_video
setlocal
set "TYPE=%~1"
set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "VENV=%ROOT%\.venv"
set "MODELS=%ROOT%\models"
set "OUTPUTS=%ROOT%\outputs"
set "CACHE=%ROOT%\cache"

REM Local cache
set "UV_CACHE_DIR=%CACHE%\uv"
set "PIP_CACHE_DIR=%CACHE%\pip"
set "UV_LINK_MODE=copy"

REM Models folder inside project
set "TRANSPARENT_BACKGROUND_FILE_PATH=%MODELS%"

echo.
echo Drag and drop a video file into this window, then press Enter.
set /p "VIDEO_PATH=Video file: "
set "VIDEO_PATH=%VIDEO_PATH:"=%"

if not exist "%VIDEO_PATH%" (
    echo File not found. Aborting.
    pause
    endlocal
    goto main_menu
)

set "PATH=%VENV%\Scripts;%VENV%\Library\bin;%PATH%"

echo [INFO] Processing video: %VIDEO_PATH%
echo [INFO] Type: %TYPE%
echo [INFO] Output folder: %OUTPUTS%

"%VENV%\Scripts\transparent-background.exe" --source "%VIDEO_PATH%" --dest "%OUTPUTS%" --type %TYPE% --mode base --resize dynamic

echo [INFO] Processing finished. Output saved in %OUTPUTS%
pause
endlocal
goto main_menu

:install_tb
cls
echo [STEP] Starting installation...

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "TOOLS=%ROOT%\tools"
set "CONDA_DIR=%TOOLS%\miniconda"
set "VENV=%ROOT%\.venv"
set "CACHE=%ROOT%\cache"
set "MODELS=%ROOT%\models"
set "OUTPUTS=%ROOT%\outputs"

REM Local cache for portability
set "UV_CACHE_DIR=%CACHE%\uv"
set "PIP_CACHE_DIR=%CACHE%\pip"
set "UV_LINK_MODE=copy"

set "MINICONDA_EXE=%TOOLS%\miniconda.exe"
set "UV_EXE=%TOOLS%\uv.exe"
set "CONDA_URL=https://repo.anaconda.com/miniconda/Miniconda3-py310_24.9.2-0-Windows-x86_64.exe"
set "UV_URL=https://github.com/astral-sh/uv/releases/latest/download/uv-x86_64-pc-windows-msvc.zip"

echo Root: %ROOT%
echo Tools: %TOOLS%
echo Cache: %CACHE%
echo UV cache: %UV_CACHE_DIR%
echo PIP cache: %PIP_CACHE_DIR%

if exist "%VENV%\python.exe" (
    echo Found existing installation.
    choice /C YN /M "Re-install? (will delete old env and cache)"
    if errorlevel 2 goto main_menu
    echo Deleting old installation...
    if exist "%VENV%" rmdir /s /q "%VENV%" 2>nul
    if exist "%CACHE%" rmdir /s /q "%CACHE%" 2>nul
    if exist "%TOOLS%" rmdir /s /q "%TOOLS%" 2>nul
    echo Old folders deleted.
)

echo [STEP] Creating folders...
if not exist "%TOOLS%" mkdir "%TOOLS%"
if not exist "%CACHE%" mkdir "%CACHE%"
if not exist "%CACHE%\uv" mkdir "%CACHE%\uv"
if not exist "%CACHE%\pip" mkdir "%CACHE%\pip"
if not exist "%MODELS%" mkdir "%MODELS%"
if not exist "%OUTPUTS%" mkdir "%OUTPUTS%"

REM Ensure system tools are available before any downloads
set "SYS_PATH=%SystemRoot%\System32"

echo [STEP] Checking Miniconda...
if exist "%CONDA_DIR%\Scripts\conda.exe" goto conda_present
echo Downloading Miniconda...
"%SYS_PATH%\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -NonInteractive -Command "Invoke-WebRequest -Uri '%CONDA_URL%' -OutFile '%MINICONDA_EXE%'"
start /wait "" "%MINICONDA_EXE%" /S /D=%CONDA_DIR%
del "%MINICONDA_EXE%" >nul 2>&1
:conda_present
echo Conda ready.

echo [STEP] Checking UV...
if exist "%UV_EXE%" goto uv_present
echo Downloading UV...
"%SYS_PATH%\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -NonInteractive -Command "Invoke-WebRequest -Uri '%UV_URL%' -OutFile '%TOOLS%\uv.zip'"
"%SYS_PATH%\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -NonInteractive -Command "Expand-Archive -Path '%TOOLS%\uv.zip' -DestinationPath '%TOOLS%' -Force"
del "%TOOLS%\uv.zip" >nul 2>&1
:uv_present
echo UV ready.

set "OLD_PATH=%PATH%"
set "PATH=%CONDA_DIR%\Scripts;%CONDA_DIR%;%TOOLS%;%PATH%"

echo [STEP] Creating conda environment...
if exist "%VENV%\python.exe" goto gpu_check
"%CONDA_DIR%\Scripts\conda.exe" create -p "%VENV%" python=3.10 -y --quiet
:gpu_check

echo [STEP] Detecting GPU...
set "HAS_GPU=0"
if exist "%SystemRoot%\System32\nvidia-smi.exe" set "HAS_GPU=1"
if exist "%ProgramFiles%\NVIDIA Corporation\NVSMI\nvidia-smi.exe" set "HAS_GPU=1"

call "%CONDA_DIR%\Scripts\activate.bat" "%VENV%"

if "%HAS_GPU%"=="1" (
    echo [INFO] Installing PyTorch with CUDA 12.8...
    uv pip install torch torchvision --extra-index-url https://download.pytorch.org/whl/cu128 --python "%VENV%\python.exe"
) else (
    echo [INFO] Installing PyTorch CPU version...
    uv pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu --python "%VENV%\python.exe"
)

echo [STEP] Installing transparent-background[gui]...
uv pip install "transparent-background[gui]" --python "%VENV%\python.exe"

echo [STEP] Installing compatible flet version...
uv pip install "flet==0.17.0" --python "%VENV%\python.exe"

if "%HAS_GPU%"=="1" (
    echo [STEP] Restoring torch CUDA...
    uv pip install --force-reinstall torch torchvision --extra-index-url https://download.pytorch.org/whl/cu128 --python "%VENV%\python.exe"
)

echo [INFO] Models will be stored in: %MODELS%
echo [INFO] UV cache: %UV_CACHE_DIR%
echo [INFO] PIP cache: %PIP_CACHE_DIR%

set "PATH=%OLD_PATH%"

echo.
echo ============================================================
echo [INFO] Installation finished!
echo ============================================================
pause
goto main_menu

:update_tb
cls
echo [STEP] Updating...

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "TOOLS=%ROOT%\tools"
set "CONDA_DIR=%TOOLS%\miniconda"
set "VENV=%ROOT%\.venv"
set "CACHE=%ROOT%\cache"

REM Local cache for portability
set "UV_CACHE_DIR=%CACHE%\uv"
set "PIP_CACHE_DIR=%CACHE%\pip"
set "UV_LINK_MODE=copy"

set "PATH=%CONDA_DIR%\Scripts;%CONDA_DIR%;%TOOLS%;%PATH%"

if not exist "%VENV%\python.exe" (
    echo Installation not found. Installing now...
    goto install_tb
)

echo [STEP] Detecting GPU...
set "HAS_GPU=0"
if exist "%SystemRoot%\System32\nvidia-smi.exe" set "HAS_GPU=1"
if exist "%ProgramFiles%\NVIDIA Corporation\NVSMI\nvidia-smi.exe" set "HAS_GPU=1"

call "%CONDA_DIR%\Scripts\activate.bat" "%VENV%"

if "%HAS_GPU%"=="1" (
    echo [INFO] Updating PyTorch with CUDA 12.8...
    uv pip install --upgrade torch torchvision --extra-index-url https://download.pytorch.org/whl/cu128 --python "%VENV%\python.exe"
) else (
    echo [INFO] Updating PyTorch CPU version...
    uv pip install --upgrade torch torchvision --index-url https://download.pytorch.org/whl/cpu --python "%VENV%\python.exe"
)

echo [INFO] Updating transparent-background[gui]...
uv pip install --upgrade "transparent-background[gui]" --python "%VENV%\python.exe"

echo [INFO] Updating flet...
uv pip install "flet==0.17.0" --python "%VENV%\python.exe"

if "%HAS_GPU%"=="1" (
    echo [INFO] Restoring torch CUDA...
    uv pip install --force-reinstall torch torchvision --extra-index-url https://download.pytorch.org/whl/cu128 --python "%VENV%\python.exe"
)

echo [INFO] Update finished.
echo [INFO] UV cache: %UV_CACHE_DIR%
echo [INFO] PIP cache: %PIP_CACHE_DIR%
pause
goto main_menu