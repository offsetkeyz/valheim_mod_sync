param (
    [string]$CSVFile
)

function Show-Usage {
    Write-Host "Usage: .\install_mods.ps1 -CSVFile <csv_file>"
    exit 1
}

function Prompt-For-Directory {
    while ($true) {
        $DEST_DIR = Read-Host "Destination directory does not exist. Please enter the destination directory"
        if (Test-Path -Path $DEST_DIR) {
            Write-Host "Using existing directory: $DEST_DIR"
            break
        } else {
            $yn = Read-Host "Directory does not exist. Do you want to create it? (y/n)"
            switch ($yn) {
                "y" {
                    New-Item -ItemType Directory -Path $DEST_DIR
                    Write-Host "Directory created: $DEST_DIR"
                    break
                }
                "n" {
                    Write-Host "Please enter a valid directory."
                    continue
                }
                default {
                    Write-Host "Please answer yes or no."
                }
            }
        }
    }
}

function Check-And-Install-Tools {
    if (-not (Get-Command wget -ErrorAction SilentlyContinue) -and -not (Get-Command curl -ErrorAction SilentlyContinue)) {
        Write-Host "wget and curl are not installed. Please install one of them."
        exit 1
    }

    if (-not (Get-Command unzip -ErrorAction SilentlyContinue)) {
        Write-Host "unzip is not installed. Installing unzip..."
        if ($PSVersionTable.PSVersion.Platform -eq "Unix") {
            if ($OSTYPE -eq "darwin") {
                brew install unzip
            } else {
                sudo apt-get install unzip -y
            }
        } else {
            Write-Host "Please install 'unzip' manually."
            exit 1
        }
    }
}

function Download-File {
    param (
        [string]$Url,
        [string]$Output
    )
    if (Get-Command wget -ErrorAction SilentlyContinue) {
        wget -O $Output $Url
    } else {
        curl -L -o $Output $Url
    }
}

if (-not $CSVFile) {
    Show-Usage
}

# Determine the destination directory based on the operating system
if ($PSVersionTable.PSVersion.Platform -eq "Unix") {
    if ($OSTYPE -eq "darwin") {
        $DEST_DIR = "$HOME/Library/Application Support/Steam/steamapps/common/Valheim/BepInEx/plugins"
        $VALHEIM_DIR = "$HOME/Library/Application Support/Steam/steamapps/common/Valheim"
    } else {
        $DEST_DIR = "$HOME/.local/share/Steam/steamapps/common/Valheim/BepInEx/plugins"
        $VALHEIM_DIR = "$HOME/.local/share/Steam/steamapps/common/Valheim"
    }
} else {
    Write-Host "Unsupported operating system."
    exit 1
}

# Check and install required tools
Check-And-Install-Tools

# Check if the destination directory exists, if not download BepInExPack
if (-not (Test-Path -Path $DEST_DIR)) {
    Write-Host "Destination directory does not exist. Downloading BepInExPack..."
    $BEPINEX_URL = "https://thunderstore.io/package/download/denikson/BepInExPack_Valheim/5.4.2202/"
    Download-File -Url $BEPINEX_URL -Output "BepInExPack_Valheim.zip"
    $TEMP_DIR = New-TemporaryFile
    Expand-Archive -Path "BepInExPack_Valheim.zip" -DestinationPath $TEMP_DIR
    Get-ChildItem -Path "$TEMP_DIR\*" | ForEach-Object { Move-Item -Path $_.FullName -Destination $VALHEIM_DIR }
    Remove-Item -Path $TEMP_DIR -Recurse
    Remove-Item -Path "BepInExPack_Valheim.zip"
}

# Clear the destination directory
Remove-Item -Recurse -Force $DEST_DIR
New-Item -ItemType Directory -Path $DEST_DIR

# Read the CSV file line by line
Import-Csv -Path $CSVFile | ForEach-Object {
    if ($_.ModName -eq "ModName") {
        return
    }

    # Construct the URL
    $URL = "https://thunderstore.io/package/download/$($_.Author)/$($_.ModName)/$($_.Version)/"

    # Download the mod
    $MOD_ZIP = "$($_.ModName).zip"
    Download-File -Url $URL -Output $MOD_ZIP

    # Create a directory for the mod
    $MOD_DIR = Join-Path -Path $DEST_DIR -ChildPath $_.ModName
    New-Item -ItemType Directory -Path $MOD_DIR

    # Extract the mod into its own folder
    Expand-Archive -Path $MOD_ZIP -DestinationPath $MOD_DIR -Force

    # Remove the zip file
    Remove-Item -Path $MOD_ZIP
}

Write-Host "All mods have been downloaded and extracted to $DEST_DIR."

#.\install_mods.ps1 -CSVFile "C:\path\to\your\requirements.csv"
