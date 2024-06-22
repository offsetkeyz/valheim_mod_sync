# Mod Installation Scripts

## Overview

This repository contains scripts to automate the installation of mods for Valheim on different operating systems. The provided scripts support macOS, SteamOS, and Windows. Each script reads a CSV file containing mod details and downloads the specified mods.

## Requirements

### General Requirements
- A CSV file with the following columns: `ModName`, `Author`, `Version`.
- An internet connection to download the mods.

### Windows
- PowerShell 5.0 or later
- `wget` or `curl`
- `Expand-Archive` cmdlet

### macOS and SteamOS
- `wget` or `curl`
- `unzip` utility
- Homebrew (for macOS, to install `unzip` if not present)

## Usage

### Windows

#### Script: `install_mods.ps1`

1. **Parameters**: 
   - `CSVFile`: Path to the CSV file containing mod details.

2. **Command**:
   ```powershell
   .\install_mods.ps1 -CSVFile <path_to_csv_file>
   ```

3. **Example**:
   ```powershell
   .\install_mods.ps1 -CSVFile "C:\pathto\your\requirements.csv"
   ```

4. **Description**:
   - The script checks if `wget` or `curl` is installed. If neither is found, it prompts the user to install one.
   - It verifies the availability of the `Expand-Archive` cmdlet.
   - If the destination directory for mods (`C:\Program Files (x86)\Steam\steamapps\common\Valheim\BepInEx\plugins`) does not exist, the script downloads and installs the BepInExPack.
   - The script reads the provided CSV file and downloads the specified mods to the appropriate directory.

### macOS and SteamOS

#### Script: `install_mods.sh`

1. **Parameters**:
   - `-o`: Operating system (`macos` or `steamdeck`)
   - `-c`: Path to the CSV file containing mod details.

2. **Command**:
   ```bash
   ./install_mods.sh -o <operating_system> -c <path_to_csv_file>
   ```

3. **Example**:
   ```bash
   ./install_mods.sh -o macos -c "/path/to/your/requirements.csv"
   ```

4. **Description**:
   - The script checks if `wget` or `curl` is installed. If neither is found, it prompts the user to install one.
   - It checks for the `unzip` utility and installs it if not present (for macOS, it uses Homebrew).
   - If the destination directory for mods does not exist, the script downloads and installs the BepInExPack.
   - The script reads the provided CSV file and downloads the specified mods to the appropriate directory.

## CSV File Format

The CSV file should have the following columns:

| ModName | Author | Version |
|---------|--------|---------|
| Mod1    | Author1| 1.0.0   |
| Mod2    | Author2| 1.2.3   |

- The first row should be the header.
- Each subsequent row should contain the details of one mod.

## Additional Information

- Ensure that the CSV file is correctly formatted and accessible.
- The scripts will create necessary directories and clean up temporary files as needed.
- If there are any issues with missing dependencies or tools, follow the prompts provided by the scripts to resolve them.

## Support

For any issues or questions, please open an issue in this repository.
