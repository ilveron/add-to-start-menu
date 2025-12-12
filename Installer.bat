@echo off
:: The next line launches the installer script bypassing the ExecutionPolicy
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Add-ScriptToContextMenu.ps1"