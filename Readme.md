# IIS Config Manager

An all in one IIS configuraiton manager for windows. This script allows you to manage IIS sites, check connection strings, encrypt and decrypt web.config files, and more.


## Prerequisites

- Windows OS with IIS(v7.0 or greater) installed
- PowerShell 5.1 or later
- Administrative privileges

## Installation/Usage

   - Clone the reporsitory and click on `IIS-Config Manager.exe` 
   - download the script file `iis_config_manager.ps1` add changes as per your need and run it with administrator privileges using PowerShell.
   - Download the latest release from the [Releases](https://github.com/N1kh1lS1ngh25/iis-config-manager/releases/download/v.1.2.2/IIS-Config.Manager.exe)



## Features

### Main Window

The main window displays a list of IIS sites with the following information:
- Number
- Site Name
- Host Name
- AppPool Status
- WebConfig Status

### Buttons

- **Refresh Sites**: Updates the list of IIS sites.
- **Check Connection String**: Displays the connection string for the selected site.(Web.config must be decrypted to view the connection string).
- **Encrypt Web.Config**: Encrypts the web.config file of the selected site (visible only for unencrypted sites).
- **Decrypt Web.Config**: Decrypts the web.config file of the selected site (visible only for encrypted sites).

## Step-by-Step Guide

1. **Launch the Application**
   - Double click the `IIS-Config Manager.exe` to run.
  (If prompted for elevated privileges, confirm to run the script as an administrator)
   - The main window will appear, displaying a list of IIS sites.

1. **Refresh Site List**
   - Click the "Refresh Sites" button to update the list of IIS sites.

2. **Select a Site**
   - Click on a site name in the list to select it.
   - The encrypt/decrypt buttons will become visible based on the site's current encryption status.

3. **Check Connection String**
   - Select a site from the list.
   - Click the "Check Connection String" button.
   - If the web.config is encrypted, you'll be prompted to decrypt it temporarily.
   - The connection string details will be displayed in the output box.

4. **Encrypt Web.Config**
   - Select an unencrypted site from the list.
   - Click the "Encrypt Web.Config" button.
   - A confirmation message will appear when encryption is complete.

5. **Decrypt Web.Config**
   - Select an encrypted site from the list.
   - Click the "Decrypt Web.Config" button.
   - A confirmation message will appear when decryption is complete.

## Troubleshooting

If you encounter any issues:

1. Ensure you're running the script with administrative privileges.
2. Check that IIS is properly installed and configured on your system.Click [here]() to install and configure IIS on your system.
3. Verify that the web.config files for your sites are accessible and not locked by another process.

## Notes

- The script automatically runs with elevated privileges if necessary.
- The PowerShell console window is hidden by default to provide a cleaner user experience.
- Web.config encryption/decryption is performed using the aspnet_regiis.exe tool.

## Feedback and Contributions

  Feel Free to :

- Report issues or suggest enhancements by creating a new issue on the [GitHub repository](https://github.com/N1kh1lS1ngh25/iis-config-manager)
- Star⭐ the repository if you find it useful.😁