#!/bin/sh

# Usage: ./vcpkg-deb-sync.sh <conf_dir> <target_dir>

set -eu

# Given a port name and a deb name, syncs target_dir with the appropriate port overlay
update_port() {
  TARGET_DIR="$1"
  VCPKG_PORT_NAME="$2"
  DEB_PACKAGE_NAME="$3"

  # Check arguments
  if [ -z "$TARGET_DIR" ] || [ -z "$VCPKG_PORT_NAME" ] || [ -z "$DEB_PACKAGE_NAME" ]; then
    echo "Usage: $0 <root_overlay_dir> <vcpkg_port_name> <deb_package_name>"
    return 1
  fi

  OVERLAY_DIR="$TARGET_DIR/$VCPKG_PORT_NAME"

  # Check if the Debian package is installed
  if ! dpkg -s "$DEB_PACKAGE_NAME" >/dev/null 2>&1; then
    if [ -d "$OVERLAY_DIR" ]; then
      rm -rf "$OVERLAY_DIR"
    fi
    return 0
  fi

  # Get Debian package version
  PACKAGE_VERSION=$(dpkg -s "$DEB_PACKAGE_NAME" | awk -F': ' '/^Version:/ { print $2 }')
  VERSION=$(echo "$PACKAGE_VERSION" | sed -E 's/^([0-9]+\.[0-9]+(\.[0-9]+)?).*/\1/')

  # Check if overlay already exists with the same version
  EXISTING_VERSION_FILE="$OVERLAY_DIR/vcpkg.json"
  if [ -f "$EXISTING_VERSION_FILE" ]; then
    CURRENT_VERSION=$(awk -F'"' '/"version":/ { print $4 }' "$EXISTING_VERSION_FILE")

    if [ "$CURRENT_VERSION" = "$VERSION" ]; then
      return 0
    fi
  fi

  # Create (or recreate) the overlay port directory
  mkdir -p "$OVERLAY_DIR"

  # Write vcpkg.json
  cat > "$OVERLAY_DIR/vcpkg.json" <<EOF
{
  "name": "$VCPKG_PORT_NAME",
  "version": "$VERSION",
  "description": "Overlay port for $VCPKG_PORT_NAME using Debian package $DEB_PACKAGE_NAME"
}
EOF

  # Write portfile.cmake
  cat > "$OVERLAY_DIR/portfile.cmake" <<EOF
set (VCPKG_POLICY_EMPTY_PACKAGE ON)
EOF
}

CONF_DIR="$1"
TARGET_DIR="$2"
MAIN_MAPPING="$CONF_DIR/mappings.json"
MAPPINGS_DIR="$CONF_DIR/mappings.d"

# Check if jq is installed
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required but not installed." >&2
  exit 1
fi

# Build the list of mapping files: main file + all *.json in mappings.d
FILES="$MAIN_MAPPING"
for f in "$MAPPINGS_DIR"/*.json; do
  [ -e "$f" ] || continue  # skip if no matches
  FILES="$FILES $f"
done

# Iterate all files to sync overlay ports
for json_file in $FILES; do
  jq -r 'to_entries[] | "\(.key) \(.value)"' "$json_file" | while IFS= read -r line; do
    deb=$(echo "$line" | awk '{print $1}')
    port=$(echo "$line" | awk '{print $2}')
    update_port "$TARGET_DIR" "$port" "$deb"
  done
done
