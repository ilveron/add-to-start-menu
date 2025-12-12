# Check if the script is running with Administrator privileges
## This is required to modify the System Registry for context menu items
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Administrator rights are required to configure the registry."
    
    # Restart the script asking for elevation
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Define the source and destination paths
## Source is the script to be installed (must be in the same folder as this installer)
$SourceFile = "Add-ShortcutToStartMenu.ps1"
$CurrentDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SourcePath = Join-Path -Path $CurrentDir -ChildPath $SourceFile

## Destination is a hidden folder in the user's AppData to ensure persistence
$DestDir = "$env:APPDATA\RightClickTools" 
$DestFile = "$DestDir\$SourceFile"

# Verify that the source file exists before proceeding
if (-not (Test-Path $SourcePath)) {
    Write-Error "File '$SourceFile' not found.`nPlease ensure both scripts are in the same folder."
    Read-Host "Press ENTER to exit..."
    return
}

# Install the script file
try {
    # Create the destination directory if it does not exist
    if (-not (Test-Path $DestDir)) {
        New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
    }

    # Copy the file to the destination
    Copy-Item -Path $SourcePath -Destination $DestFile -Force
    Write-Host "Script successfully installed to: $DestDir" -ForegroundColor Cyan
}
catch {
    Write-Error "Error copying the file: $_"
    Read-Host "Press ENTER to exit..."
    return
}

# Configure the Windows Registry
try {
    # Define the registry path for .exe context menu
    $RegPath = "Registry::HKEY_CLASSES_ROOT\exefile\shell\AddShortcutToStart"
    $MenuText = "Add Shortcut to Start Menu" # Text displayed in the context menu
    
    # Define the command to execute
    ## Uses -WindowStyle Hidden to avoid showing the console window
    ## Uses -ExecutionPolicy Bypass to run without restrictions
    ## Passes %1 (the selected file path) as an argument to the script
    $Command = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$DestFile`" `"%1`""

    # Create the registry keys
    New-Item -Path $RegPath -Force | Out-Null
    Set-ItemProperty -Path $RegPath -Name "(default)" -Value $MenuText
    
    New-Item -Path "$RegPath\command" -Force | Out-Null
    Set-ItemProperty -Path "$RegPath\command" -Name "(default)" -Value $Command
    
    Write-Host "`nInstallation completed successfully!" -ForegroundColor Green
    Write-Host "You can now right-click any .exe file and select '$MenuText'."
}
catch {
    Write-Error "Error writing to registry: $_"
}

# Pause before closing to let user read the output
Read-Host "`nPress ENTER to close..."