#!/bin/bash

# Function to display usage information
usage() {
  echo "Usage: $0 -o <operating_system> -c <csv_file>"
  echo "Operating Systems: macos, steamdeck, windows"
  exit 1
}

# Function to prompt for directory if it doesn't exist
prompt_for_directory() {
  while true; do
    read -p "Destination directory does not exist. Please enter the destination directory: " DEST_DIR
    if [ -d "$DEST_DIR" ]; then
      echo "Using existing directory: $DEST_DIR"
      break
    else
      read -p "Directory does not exist. Do you want to create it? (y/n): " yn
      case $yn in
        [Yy]* ) mkdir -p "$DEST_DIR"; echo "Directory created: $DEST_DIR"; break;;
        [Nn]* ) echo "Please enter a valid directory."; continue;;
        * ) echo "Please answer yes or no.";;
      esac
    fi
  done
}

# Function to check and install required tools
check_and_install_tools() {
  if ! command -v wget &> /dev/null && ! command -v curl &> /dev/null; then
    echo "wget and curl are not installed. Please install one of them."
    exit 1
  fi

  if ! command -v unzip &> /dev/null; then
    echo "unzip is not installed. Installing unzip..."
    if [[ "$OS" == "macos" ]]; then
      brew install unzip
    else
      sudo apt-get install unzip -y
    fi
  fi
}

# Function to download files
download_file() {
  URL="$1"
  OUTPUT="$2"
  if command -v wget &> /dev/null; then
    wget -O "$OUTPUT" "$URL"
  else
    curl -L -o "$OUTPUT" "$URL"
  fi
}

# Parse command-line arguments
while getopts "o:c:" opt; do
  case $opt in
    o) OS="$OPTARG" ;;
    c) CSV_FILE="$OPTARG" ;;
    *) usage ;;
  esac
done

# Check if both arguments are provided
if [ -z "$OS" ] || [ -z "$CSV_FILE" ]; then
  usage
fi

# Set the destination directory based on the operating system
case $OS in
  macos)
    DEST_DIR="$HOME/Library/Application Support/Steam/steamapps/common/Valheim/BepInEx/plugins"
    VALHEIM_DIR="$HOME/Library/Application Support/Steam/steamapps/common/Valheim"
    ;;
  steamdeck)
    DEST_DIR="$HOME/.local/share/Steam/steamapps/common/Valheim/BepInEx/plugins"
    VALHEIM_DIR="$HOME/.local/share/Steam/steamapps/common/Valheim"
    ;;
  windows)
    DEST_DIR="$HOME/../../Program Files (x86)/Steam/steamapps/common/Valheim/BepInEx/plugins"
    VALHEIM_DIR="$HOME/../../Program Files (x86)/Steam/steamapps/common/Valheim"
    ;;
  *)
    usage
    ;;
esac

# Check and install required tools
check_and_install_tools

# Check if the destination directory exists, if not download BepInExPack
if [ ! -d "$DEST_DIR" ]; then
  echo "Destination directory does not exist. Downloading BepInExPack..."
  BEPINEX_URL="https://thunderstore.io/package/download/denikson/BepInExPack_Valheim/5.4.2202/"
  download_file "$BEPINEX_URL" "BepInExPack_Valheim.zip"
  TEMP_DIR=$(mktemp -d)
  unzip -o "BepInExPack_Valheim.zip" -d "$TEMP_DIR"
  mv "$TEMP_DIR"/*/* "$VALHEIM_DIR"
  rm -r "$TEMP_DIR"
  rm "BepInExPack_Valheim.zip"
fi

# Clear the destination directory
rm -rf "$DEST_DIR"
mkdir -p "$DEST_DIR"

# Read the CSV file line by line
while IFS=, read -r ModName Author Date Version; do
  # Skip the header row
  if [[ "$ModName" == "ModName" ]]; then
    continue
  fi

  # Construct the URL
  URL="https://thunderstore.io/package/download/${Author}/${ModName}/${Version}/"

  # Download the mod
  download_file "$URL" "${ModName}.zip"

  # Create a directory for the mod
  MOD_DIR="${DEST_DIR}/${ModName}"
  mkdir -p "$MOD_DIR"

  # Extract the mod into its own folder
  unzip -o "${ModName}.zip" -d "$MOD_DIR"

  # Remove the zip file
  rm "${ModName}.zip"

done < "$CSV_FILE"

echo "All mods have been downloaded and extracted to $DEST_DIR."
