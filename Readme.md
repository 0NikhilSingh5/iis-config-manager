# IIS Site Manager

## Overview
The **IIS Site Manager** is a PowerShell-based GUI tool designed to manage IIS sites effectively. It provides functionalities such as:

- Listing all IIS sites with their details.
- Checking and displaying connection strings from web.config files.
- Encrypting and decrypting the connection strings within web.config.
- Refreshing site information dynamically.

This tool is particularly useful for administrators who need an easy way to manage IIS site configurations and security settings.

---

## Features
- ✅ **Graphical User Interface (GUI)** for ease of use.
- 🔍 **View IIS site details**, including hostname, application pool status, and web.config encryption status.
- 🔐 **Encrypt and decrypt web.config connection strings**.
- 🔄 **Refresh site details dynamically**.
- 📜 **Retrieve and display connection strings securely**.

---

## Prerequisites
Ensure your system meets the following requirements before running the script:

- **Windows OS** with IIS installed.
- **PowerShell (Admin Mode)**
- **.NET Framework 4.0 or later**

### Required PowerShell Modules
This script uses the `WebAdministration` module to interact with IIS.

To install it, run:
```powershell
Install-Module -Name WebAdministration -Force
```

---

## Installation & Usage

### Step 1: Running the Script
1. Open **PowerShell as Administrator**.
2. Run the script using:
   ```powershell
   .\IIS-Site-Manager.ps1
   ```

### Step 2: Navigating the GUI
Once the script runs, you’ll see the **IIS Site Manager** interface:

- **ListView Panel**: Displays all IIS sites with their details.
- **Output Box**: Shows connection string details.
- **Buttons**:
  - **Refresh Sites**: Reloads IIS site data.
  - **Check Connection String**: Retrieves database credentials from web.config.
  - **Encrypt Web.Config**: Secures the connection strings.
  - **Decrypt Web.Config**: Reveals the encrypted connection strings.

---

## Functionalities Explained

### 🔍 Fetching IIS Site Details
The script retrieves IIS sites using:
```powershell
Get-ChildItem IIS:\Sites
```
This fetches site names, bindings, and application pool statuses.

### 🔐 Encryption & Decryption
Uses `aspnet_regiis.exe` to encrypt/decrypt connection strings in `web.config`:
```powershell
& "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis.exe" -pef "connectionStrings" "$physicalpath"
```

### 📜 Retrieving Connection Strings
Extracts connection strings from web.config and displays them in a formatted manner:
```powershell
[xml]$webConfig = Get-Content $webConfigPath
$connectionStrings = $webConfig.configuration.connectionStrings.add | Where-Object { $_.name -eq "ProjectX" }
```

---

## Example Output
When you check connection strings, the tool displays:
```plaintext
Connection String Details:
-------------------------
Server  : db-server.domain.com
Database: ProjectX_DB
Username: admin_user
Password: ********
Extra   : Encrypt=True;TrustServerCertificate=False
-------------------------
```

---

## Troubleshooting

### 🛑 IIS Not Found Error
- Ensure IIS is installed and running.
- Run PowerShell as an **Administrator**.

### 🔄 Web.Config Not Found
- Verify the site has a `web.config` file in its root directory.
- Ensure the correct permissions are set.

### 🔐 Encryption Issues
- Make sure the correct .NET Framework version is installed.
- Run the script in **Administrator mode**.

---

## Author
**Nikhil Singh** - DevOps Engineer & Automation Specialist 🚀

🔗 [LinkedIn](https://www.linkedin.com/in/nikhil-singh)

---

## License
This project is open-source and available under the **MIT License**.

