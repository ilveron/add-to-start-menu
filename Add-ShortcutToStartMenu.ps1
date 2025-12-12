# SourcePath is passed as first parameter to the script
param(
    [string] $TargetPath
)

Set-Variable -Name RESERVED_FILENAMES -Option ReadOnly -Value @(
        # MS-DOS
        "CON",      # Console (input/output)
        "PRN",      # Printer
        "AUX",      # Auxiliary device (serial port)
        "NUL",      # Null device (like Linux's /dev/null)
        
        # Serial and Parallel ports
        "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9", # Serial
        "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9"  # Parallel
    )

# Few chars, making a 2 step regex generation didn't make sense
$IllegalCharsRegex = '[<>:"/\\|?*]'

function Assert-IsValidFileName {
    param (
        [string] $FileName
    )
    
    # Check if it is a reserved filename
    # or it matches any illegal chars
    if ($Script:RESERVED_FILENAMES -contains $FileName.ToUpper() -or $FileName -match $Script:IllegalCharsRegex) {
        return $false
    }

    return $true
}

function Save-Shortcut {
    param (
        [string] $TargetPath,
        [string] $SavePath
        # Ho rimosso $FileName da qui perché non veniva usato e creava confusione nei parametri
    )
    # Create the shortcut by using a ComObject
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($SavePath)
    $Shortcut.TargetPath = $TargetPath
    $Shortcut.Save()
}

function Get-ShortcutName {
    param (
        [string] $FileName
    )
    
    # Load the necessary assemblies to draw the form
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # Define the main window (Form)
    $Form = New-Object System.Windows.Forms.Form
    $Form.Text = "Create Shortcut"
    $Form.Size = New-Object System.Drawing.Size(400,200)
    $Form.StartPosition = "CenterScreen"
    $Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $Form.MaximizeBox = $false

    # Define the Label
    $LblMessage = New-Object System.Windows.Forms.Label
    $LblMessage.Location = New-Object System.Drawing.Point(20,20)
    $LblMessage.Size = New-Object System.Drawing.Size(350,30)
    $LblMessage.Text = "Insert a custom name for your shortcut:`n(Leave empty to keep: '$FileName')"

    # Define the TextBox
    $TxtName = New-Object System.Windows.Forms.TextBox
    $TxtName.Location = New-Object System.Drawing.Point(20,60)
    $TxtName.Size = New-Object System.Drawing.Size(340,20)

    # Define the OK Button
    $BtnOk = New-Object System.Windows.Forms.Button
    $BtnOk.Location = New-Object System.Drawing.Point(260,100)
    $BtnOk.Size = New-Object System.Drawing.Size(100,30)
    $BtnOk.Text = "OK"
    $BtnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK

    # Add controls to the form
    $Form.Controls.Add($LblMessage)
    $Form.Controls.Add($TxtName)
    $Form.Controls.Add($BtnOk)
    $Form.AcceptButton = $BtnOk
    
    $Loop = $true

    do {
        # Draw the complete form
        $Result = $Form.ShowDialog()
        
        # If the user clicked the OK button
        if ($Result -eq [System.Windows.Forms.DialogResult]::OK) {
            # Save the text inside the TextBox
            $InputName = $TxtName.Text.Trim()

            # If the user left the TextBox empty
            if ([string]::IsNullOrWhiteSpace($InputName)){
                $Loop = $false
            }
            # If the user provided a name, validate it
            ## If the name is not valid, show an error message (and continue)
            elseif (-not (Assert-IsValidFileName -FileName $InputName)) {
                $ErrorMessage = "The name provided ('$InputName') is not valid as a Windows filename.`n"
                    + "It contains invalid characters or it matches a reserved name."

                [System.Windows.Forms.MessageBox]::Show(
                    $ErrorMessage, "Provided Filename is Invalid",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error)
                
                # $Loop is still false, hence the Form is shown again
            }
            # The Name is valid, hence update $FileName and stop the loop
            else {
                $FileName = $InputName
                $Loop = $false
            }
        } else { return $null } # Cancel pressed or window closed
    } while ($Loop)

    return $FileName
}

# --- MAIN LOGIC ---

# Basic Validation: If TargetPath is empty, exit
if ([string]::IsNullOrWhiteSpace($TargetPath)) {
    return
}

# Determine what the shortcut name will be
## Default to original filename
### Example TargetPath - C:\aaaa\bbbb\cccc.exe
### FileName - cccc
try {
    # Using .NET logic is safer than splitting strings manually
    $FileName = [System.IO.Path]::GetFileNameWithoutExtension($TargetPath)
}
catch {
    # Fallback to manual split if needed
    $FileName = $TargetPath.split('\')[-1].split('.')[0]
}

## Ask user whether they want to use a custom name for the shortcut
$FileName = Get-ShortcutName $FileName

# Only proceed if we have a valid filename (user didn't cancel)
if ($null -ne $FileName) {
    # Define SavePath for the shortcut
    $StartMenuPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
    
    # Ensure directory exists
    if (-not (Test-Path $StartMenuPath)) { New-Item -ItemType Directory -Path $StartMenuPath | Out-Null }
    
    $SavePath = Join-Path -Path $StartMenuPath -ChildPath ($FileName + ".lnk")

    # This does the magic!
    Save-Shortcut $TargetPath $SavePath
}