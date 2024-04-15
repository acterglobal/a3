#!/bin/bash

# Exit if any command fails
set -e

# Echo all commands for debug purposes
set -x

# to be run from root

echo "New Version: $1"
TARGET_PATH=app/flatpak/global.acter.a3.metainfo_versions.xml

cp $TARGET_PATH app/flatpak/global.acter.a3.metainfo_versions_old.xml

cat > $TARGET_PATH << EOF
    <release version="$1" date="$(date +%Y-%m-%d)">
        <url type="details">https://github.com/acterglobal/a3/releases/tag/v$1</url>
        <description>
EOF

cat CHANGELOG.md >> $TARGET_PATH

cat >> $TARGET_PATH << EOF
        </description>
    </release>
EOF

cat app/flatpak/global.acter.a3.metainfo_versions_old.xml >> $TARGET_PATH