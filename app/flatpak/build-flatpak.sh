#!/bin/bash


# Convert the archive of the Flutter app to a Flatpak.


# Exit if any command fails
set -e

# Echo all commands for debug purposes
set -x


# No spaces in project name.
projectName=Acter
projectId=global.acter.a3
executableName=acter

ls -ltas .
ls -ltas build/
ls -ltas /app

# ------------------------------- Build Flatpak ----------------------------- #
# Copy the app to the Flatpak-based location.
mkdir -p /app/bin
cp -r build/ /app/$projectName
chmod +x /app/$projectName/$executableName
ln -s /app/$projectName/$executableName /app/bin/$executableName

# Install the icon.
iconDir=/app/share/icons/hicolor/scalable/apps
mkdir -p $iconDir
cp -r acter-logo.svg $iconDir/$projectId.svg

# Install the desktop file.
desktopFileDir=/app/share/applications
mkdir -p $desktopFileDir
cp -r $projectId.desktop $desktopFileDir/

# generate the appstream metainfo file
cat $projectId.metainfo_header.xml > $projectId.metainfo.xml
cat $projectId.metainfo_versions.xml >> $projectId.metainfo.xml

# Install the AppStream metadata file.
metadataDir=/app/share/metainfo
mkdir -p $metadataDir
cp -r $projectId.metainfo.xml $metadataDir/
