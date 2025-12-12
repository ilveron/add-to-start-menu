# Add to Start Menu

A simple Windows utility that adds an **"Add Shortcut To Start Menu"** option to the right-click context menu of any `.exe` file.

This tool is designed for portable applications or standalone executables that don't have their own installer. Unlike the native Windows **"Pin to Start"** feature—which forces the shortcut to use the original filename—this tool allows you to **set a custom name** immediately during creation.

![Right Click Context Menu Example](https://i.ibb.co/tTrdVQFS/explorer-Mgs-BXBo-TWw.png)

## Features

* **Custom Naming:** The main advantage over the standard "Pin to Start". It opens a dialog window letting you choose exactly how the app will appear in your Start Menu (e.g., renaming `app_v2.4_portable.exe` to just `My App`).
* **Context Menu Integration:** Adds a native option to Windows Explorer for executable files.
* **Input Validation:** Automatically checks for invalid characters and reserved filenames (e.g., CON, PRN) to prevent errors.
* **User-Level Access:** Shortcuts are saved to `%APPDATA%`, so you don't need Administrator privileges to use the tool after installation.

## Installation

1.  Download the latest release and extract the ZIP file to a folder.
2.  Double-click on **`Install.bat`**.

> **Note:** The `Install.bat` file is a wrapper that temporarily bypasses PowerShell execution policies to allow the installation script to run. You may receive a UAC prompt as the script requires Administrator privileges to modify the Windows Registry.

![Installation Success](https://i.ibb.co/KzptQHRz/powershell-oj-Z2-RMQ038.png)

## Usage

1.  Right-click on any `.exe` file.
2.  If using Windows 11, click on **Show More Options**
3.  Select **"Add Shortcut To Start Menu"**.
4.  A window will appear asking for the name of the shortcut (defaults to the filename if left empty).
5.  Click **OK**. The shortcut will appear in your Start Menu immediately.

![Name Input Form](https://i.ibb.co/9mnnqcWR/powershell-V9-Zu76-QLDi.png)

## How it Works

The repository contains three files:

* **`Install.bat`**: A batch file that launches the installer with `-ExecutionPolicy Bypass`. This ensures the script runs regardless of the user's local PowerShell security settings.
* **`Add-ScriptToContextMenu.ps1`**: The setup script. It copies the core logic to a hidden folder in `%APPDATA%\RightClickTools` and adds the necessary keys to `HKEY_CLASSES_ROOT\exefile\shell`.
* **`Add-ShortcutToStartMenu.ps1`**: The core script invoked by the context menu. It handles the GUI (Windows Forms) and creates the actual shortcut using WScript.Shell.

## Uninstallation

To remove the tool manually:

1.  Open **Registry Editor** (`regedit`).
2.  Delete the key: `HKEY_CLASSES_ROOT\exefile\shell\AddShortcutToStart`.
3.  Delete the folder: `%APPDATA%\RightClickTools`.

## Disclaimer

This software is provided "as is", without warranty of any kind.
