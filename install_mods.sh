#!/bin/bash

# Function to display usage information
usage() {
  echo "Usage: $0 -o <operating_system> -c <csv_file> OPTIONAL"
  echo "Operating Systems: macos, steamdeck, windows"
  echo "Default CSV is requirements.csv included in the package."
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
if [ -z "$OS" ]; then
  usage
fi

# Set the destination directory based on the operating system
case $OS in
  macos)
    DEST_DIR="$HOME/Library/Application Support/Steam/steamapps/common/Valheim/BepInEx"
    VALHEIM_DIR="$HOME/Library/Application Support/Steam/steamapps/common/Valheim"
    ;;
  steamdeck)
    DEST_DIR="$HOME/.local/share/Steam/steamapps/common/Valheim/BepInEx"
    VALHEIM_DIR="$HOME/.local/share/Steam/steamapps/common/Valheim"
    ;;
  windows)
    DEST_DIR="$HOME/../../Program Files (x86)/Steam/steamapps/common/Valheim/BepInEx"
    VALHEIM_DIR="$HOME/../../Program Files (x86)/Steam/steamapps/common/Valheim"
    ;;
  *)
    usage
    ;;
esac

# Get the directory of the currently running script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CONFIG_DIR="${SCRIPT_DIR}/config"


# Check and install required tools
check_and_install_tools

# Check if the destination directory exists, if not download BepInExPack
if [ ! -d "$DEST_DIR/plugins" ]; then
  echo "Destination directory does not exist. Downloading BepInExPack..."
  BEPINEX_URL="https://thunderstore.io/package/download/denikson/BepInExPack_Valheim/5.4.2202/"
  download_file "$BEPINEX_URL" "BepInExPack_Valheim.zip"
  TEMP_DIR=$(mktemp -d)
  unzip -o "BepInExPack_Valheim.zip" -d "$TEMP_DIR"
  mv "$TEMP_DIR"/*/* "$VALHEIM_DIR"
  rm -r "$TEMP_DIR"
  rm "BepInExPack_Valheim.zip"

  echo "Changing to $VALHEIM_DIR directory"
  cd "$VALHEIM_DIR"

  START_GAME_SCRIPT="start_game_bepinex.sh"

  echo "Setting executable permissions for start_server_bepinex.sh"
  chmod u+x $START_GAME_SCRIPT

  if [ -x $START_GAME_SCRIPT ]; then
    echo "Permissions successfully changed."
  else
    echo "Failed to change permissions."
  fi

  echo "Modifying the last lines of start_server_bepinex.sh"
  sed -i '$ d' $START_GAME_SCRIPT  # Remove the last line
  sed -i '$ d' $START_GAME_SCRIPT  # Remove the second last line

  echo '    exec "$exec" -console' >> $START_GAME_SCRIPT
  echo 'fi' >> $START_GAME_SCRIPT
  echo "Verifying the contents of start_server_bepinex.sh"

  # Define the expected hash
  EXPECTED_HASH="4d7ee00db93c456b88beecd763acca844f0a1f5cc8afbdd0a0066fddabf4bfed"

  # Compute the actual hash of the file
  ACTUAL_HASH=$(sha256sum "$START_GAME_SCRIPT" | awk '{ print $1 }')

    # Compare the actual hash with the expected hash
  if [ "$ACTUAL_HASH" == "$EXPECTED_HASH" ]; then
      echo "Hash matches: $ACTUAL_HASH"
  else
      echo "Hash does not match. Expected: $EXPECTED_HASH, but got: $ACTUAL_HASH"
  fi

fi



# Clear the destination directory
rm -rf "$DEST_DIR/plugins"
mkdir -p "$DEST_DIR/plugins"

# Check if both arguments are provided
if [ -z "$CSV_FILE" ]; then
  CSV_FILE="$SCRIPT_DIR/requirements.csv"
fi

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
  MOD_DIR="${DEST_DIR}/plugins/${ModName}"
  mkdir -p "$MOD_DIR"

  # Extract the mod into its own folder
  unzip -o "${ModName}.zip" -d "$MOD_DIR"

  # Remove the zip file
  rm "${ModName}.zip"

done < "$CSV_FILE"

echo "Removing config files..."
rm -rf "$DEST_DIR/config"
echo "Copying config files..."
cp -r "$CONFIG_DIR" "$DEST_DIR/config" -v


echo "All mods have been downloaded and extracted to $DEST_DIR."
