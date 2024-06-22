#!/bin/bash

# Path to the CSV file
CSV_FILE="/home/deck/Downloads/requirements.csv"

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

# Destination directory
DEST_DIR="/home/deck/.local/share/Steam/steamapps/common/Valheim/BepInEx/plugins"

# Check if the destination directory exists, if not prompt the user
if [ ! -d "$DEST_DIR" ]; then
  prompt_for_directory
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
  wget -O "${ModName}.zip" "$URL"

  # Create a directory for the mod
  MOD_DIR="${DEST_DIR}/${ModName}"
  mkdir -p "$MOD_DIR"

  # Extract the mod into its own folder
  unzip -o "${ModName}.zip" -d "$MOD_DIR"

  # Remove the zip file
  rm "${ModName}.zip"

done < "$CSV_FILE"

echo "All mods have been downloaded and extracted to $DEST_DIR."

