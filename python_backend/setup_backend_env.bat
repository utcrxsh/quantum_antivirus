@echo off
REM Quantum Antivirus Project - Backend Environment Setup Script

REM Navigate to the backend directory
cd /d %~dp0

REM Create virtual environment if it doesn't exist
if not exist venv (
    python -m venv venv
)

REM Activate the virtual environment
call venv\Scripts\activate

REM Upgrade pip
python -m pip install --upgrade pip

REM Install dependencies
pip install -r requirements.txt

REM Deactivate virtual environment
REM (Uncomment the next line if you want to auto-deactivate after install)
REM deactivate

echo Backend environment setup complete.
pause 