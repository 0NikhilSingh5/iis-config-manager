Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Import-Module WebAdministration


# Check for admin rights and relaunch if necessary
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Exit
}

# Hide the PowerShell console window
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
$consolePtr = [Console.Window]::GetConsoleWindow()
[Console.Window]::ShowWindow($consolePtr, 0) # 0 = hide

<# ========================FUNCTIONS======================== #>


# Output box message
function Write-OutputBox($message) {
    $outputBox.AppendText($message + "`r`n")
    $outputBox.ScrollToCaret()
}
# custom Table formatting (used for console)
function Format-CustomTable($data) {
    if ($data.Count -eq 0) { return }

    $properties = @("Number", "Name", "HostName", "AppPoolStatus", "WebConfigStatus")
    $columnWidths = @{}

    # Calculate maximum width for each column
    foreach ($prop in $properties) {
        $maxLength = ($data | ForEach-Object { "$($_.$prop)".Length } | Measure-Object -Maximum).Maximum
        $columnWidths[$prop] = [Math]::Max($maxLength, $prop.Length)
    }

    # Create header
    $header = $properties | ForEach-Object { $_.PadRight($columnWidths[$_]) }
    $headerLine = $header -join " | "
    Write-Host $headerLine
    Write-Host ("-" * $headerLine.Length)

    # Create rows
    foreach ($item in $data) {
        $row = $properties | ForEach-Object { "$($item.$_)".PadRight($columnWidths[$_]) }
        Write-Host ($row -join " | ")
    }
}

# Fetech Connection Strings
function Get-ConnectionString($webConfigPath) {
    [xml]$webConfig = Get-Content $webConfigPath
    $connectionStrings = $webConfig.configuration.connectionStrings.add | Where-Object { $_.name -eq "ProjectX" }
    
    $result = @()
    foreach ($conn in $connectionStrings) {
        $connString = $conn.connectionString
        if ($connString -match "Server=([^;]+);Database=([^;]+);Uid=([^;]+);Pwd=([^;]+);(.*)") {
            $result += [PSCustomObject]@{
                Server   = $Matches[1]
                Database = $Matches[2]
                Username = $Matches[3]
                Password = $Matches[4]
                Extra    = $Matches[5]
            }
        }
    }
    return $result
}

#Display Connection String Details
function DisplayConnectionStrings($connectionStrings) {
    $output = @()
    foreach ($conn in $connectionStrings) {
        $output += "Connection String Details:"
        $output += "-------------------------"
        $output += "Server  : $($conn.Server)"
        $output += "Database: $($conn.Database)"
        $output += "Username: $($conn.Username)"
        $output += "Password: $($conn.Password)"
        $output += "Extra   : $($conn.Extra)"
        $output += "-------------------------"
        $output += ""
    }
    return $output -join [Environment]::NewLine
}

# Check Web.config file Encryption 
function Is_WebConfigEncrypted($webConfigPath) {
   $content = Get-Content $webConfigPath -Raw
    return $content -match "configProtectionProvider"
}

# Decrypt Web.config file
function Decrypt_WebConfig($physicalpath) {
   $aspnetRegiisPath = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis.exe"
    & $aspnetRegiisPath -pdf "connectionStrings" "$physicalpath"
    Write-OutputBox "Decryption completed."
}

# Re-Encrypt Web.config file
function Encrypt_WebConfig($physicalpath) {
    $aspnetRegiisPath = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis.exe"
    & $aspnetRegiisPath -pef "connectionStrings" "$physicalpath"
    Write-OutputBox "Encryption completed."
}

# Function to populate ListView with sites
function PopulateSites {
    $listView.Items.Clear()
    try {
        $sites = Get-ChildItem IIS:\Sites | ForEach-Object {
            $siteName = $_.Name
            $hostName = $_.Bindings.Collection[0].bindingInformation.Split(":")[-1]
            $appPoolStatus = (Get-WebAppPoolState -Name $_.ApplicationPool).Value
            $webConfigPath = Join-Path $_.PhysicalPath "web.config"
            $physicalPath = $_.PhysicalPath
            $webConfigStatus = if (Test-Path $webConfigPath) {
                $isEncrypted = Is_WebConfigEncrypted $webConfigPath
                if ($null -eq $isEncrypted) { "Error" } 
                elseif ($isEncrypted) { "Encrypted" } 
                else { "Not Encrypted" }
            }
            else {
                "Not Found"
            }
        
            [PSCustomObject]@{
                Number          = $null
                Name            = $siteName
                HostName        = $hostName
                AppPoolStatus   = $appPoolStatus
                WebConfigStatus = $webConfigStatus
                WebConfigPath   = $webConfigPath
                PhysicalPath    = $physicalPath
            }
        }
        
        for ($i = 0; $i -lt $sites.Count; $i++) {
            $sites[$i].Number = $i + 1
            $item = New-Object System.Windows.Forms.ListViewItem($sites[$i].Number)
            $item.SubItems.Add($sites[$i].Name)
            $item.SubItems.Add($sites[$i].HostName)
            $item.SubItems.Add($sites[$i].AppPoolStatus)
            $item.SubItems.Add($sites[$i].WebConfigStatus)
            $item.Tag = $sites[$i]
            $listView.Items.Add($item)
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error occurred while retrieving IIS sites: $_`nPlease ensure you're running this script as an administrator and that IIS is properly installed and configured.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

#Refresh selected sites
function RefreshSelectedSite {
    $selectedItems = $listView.SelectedItems
    if ($selectedItems.Count -eq 1) {
        $selectedSite = $selectedItems[0].Tag
        $webConfigPath = $selectedSite.WebConfigPath
        $webConfigStatus = if (Test-Path $webConfigPath) {
            $isEncrypted = Is_WebConfigEncrypted $webConfigPath
            if ($null -eq $isEncrypted) { "Error" } 
            elseif ($isEncrypted) { "Encrypted" } 
            else { "Not Encrypted" }
        }
        else {
            "Not Found"
        }
        $selectedSite.WebConfigStatus = $webConfigStatus
        $selectedItems[0].SubItems[4].Text = $webConfigStatus
        
        if ($webConfigStatus -eq "Encrypted") {
            $encryptButton.Visible = $false
            $decryptButton.Visible = $true
        } elseif ($webConfigStatus -eq "Not Encrypted") {
            $encryptButton.Visible = $true
            $decryptButton.Visible = $false
        } else {
            $encryptButton.Visible = $false
            $decryptButton.Visible = $false
        }
    }
}

<# ========================VIEWS======================== #>

# main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "IIS Site Manager"
$form.Size = New-Object System.Drawing.Size(680,503)
$form.StartPosition = "CenterScreen"

# ListView to display sites
$listView = New-Object System.Windows.Forms.ListView
$listView.Location = New-Object System.Drawing.Point(10,10)
$listView.Size = New-Object System.Drawing.Size(644,200)
$listView.View = [System.Windows.Forms.View]::Details
$listView.FullRowSelect = $true
$listView.Columns.Add("Number", 50)
$listView.Columns.Add("Site Name", 200)
$listView.Columns.Add("Host Name", 200)
$listView.Columns.Add("AppPool Status", 90)
$listView.Columns.Add("WebConfig Status", 100)
$form.Controls.Add($listView)

# Output Textbox
$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Location = New-Object System.Drawing.Point(10,220)
$outputBox.Size = New-Object System.Drawing.Size(644,200)
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$form.Controls.Add($outputBox)

<# ========================BUTTONS======================== #>

# Button to refresh sites
$refreshButton = New-Object System.Windows.Forms.Button
$refreshButton.Location = New-Object System.Drawing.Point(10, 430)
$refreshButton.Size = New-Object System.Drawing.Size(100, 30)
$refreshButton.Text = "Refresh Sites"
$form.Controls.Add($refreshButton)

# Button to check connection string
$checkButton = New-Object System.Windows.Forms.Button
$checkButton.Location = New-Object System.Drawing.Point(120, 430)
$checkButton.Size = New-Object System.Drawing.Size(150, 30)
$checkButton.Text = "Check Connection String"
$form.Controls.Add($checkButton)

# Button to encrypt web.config
$encryptButton = New-Object System.Windows.Forms.Button
$encryptButton.Location = New-Object System.Drawing.Point(280, 430)
$encryptButton.Size = New-Object System.Drawing.Size(120, 30)
$encryptButton.Text = "Encrypt Web.Config"
$encryptButton.Visible = $false
$form.Controls.Add($encryptButton)

# Button to decrypt web.config
$decryptButton = New-Object System.Windows.Forms.Button
$decryptButton.Location = New-Object System.Drawing.Point(410, 430)
$decryptButton.Size = New-Object System.Drawing.Size(120, 30)
$decryptButton.Text = "Decrypt Web.Config"
$decryptButton.Visible = $false
$form.Controls.Add($decryptButton)

#====================================================================#

$listView.Add_SelectedIndexChanged({
    $selectedItems = $listView.SelectedItems
    if ($selectedItems.Count -eq 1) {
        $selectedSite = $selectedItems[0].Tag
        if ($selectedSite.WebConfigStatus -eq "Encrypted") {
            $encryptButton.Visible = $false
            $decryptButton.Visible = $true
            $checkButton.Visible = $true
        } elseif ($selectedSite.WebConfigStatus -eq "Not Encrypted") {
            $encryptButton.Visible = $true
            $decryptButton.Visible = $false
            $checkButton.Visible = $true
        } else {
            $encryptButton.Visible = $false
            $decryptButton.Visible = $false
            $checkButton.Visible = $false
        }
    } else {
        $encryptButton.Visible = $false
        $decryptButton.Visible = $false
        $checkButton.Visible = $false
    }
})

# Encrypt/Decrypt Button Click Event
$encryptButton.Add_Click({
    $selectedItems = $listView.SelectedItems
    if ($selectedItems.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Please select a site first.", "Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }
    
    $selectedSite = $selectedItems[0].Tag
    Encrypt_WebConfig $selectedSite.PhysicalPath
    RefreshSelectedSite
    [System.Windows.Forms.MessageBox]::Show("Web.config has been encrypted.", "Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
})

$decryptButton.Add_Click({
    $selectedItems = $listView.SelectedItems
    if ($selectedItems.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Please select a site first.", "Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }
    
    $selectedSite = $selectedItems[0].Tag
    Decrypt_WebConfig $selectedSite.PhysicalPath
    RefreshSelectedSite
    [System.Windows.Forms.MessageBox]::Show("Web.config has been decrypted. You can now check the connection string.", "Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
})
# Refresh button click event
$refreshButton.Add_Click({ PopulateSites })

# Check Connection String button click event
$checkButton.Add_Click({
    $selectedItems = $listView.SelectedItems
    if ($selectedItems.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Please select a site first.", "Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }
    
    $selectedSite = $selectedItems[0].Tag
    
    if ($selectedSite.WebConfigStatus -eq "Encrypted") {
        $decrypt = [System.Windows.Forms.MessageBox]::Show("The web.config is encrypted. Do you want to decrypt it?", "Confirmation", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($decrypt -eq [System.Windows.Forms.DialogResult]::Yes) {
            Decrypt_WebConfig $selectedSite.PhysicalPath
            $connectionString = Get-ConnectionString $selectedSite.WebConfigPath
            $output = DisplayConnectionStrings $connectionString
            $outputBox.Text = $output
            [System.Windows.Forms.MessageBox]::Show("Press OK to re-encrypt the web.config", "Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            Encrypt_WebConfig $selectedSite.PhysicalPath
            RefreshSelectedSite
        }
    }
    else {
        $connectionString = Get-ConnectionString $selectedSite.WebConfigPath
        $output = DisplayConnectionStrings $connectionString
        $outputBox.Text = $output
    }
})

# Populate sites on form load
PopulateSites

# Show the form
$form.ShowDialog()