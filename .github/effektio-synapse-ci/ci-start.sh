#!/bin/bash
set -e
export SYNAPSE_SERVER_NAME=ds9.effektio.org
export SYNAPSE_REPORT_STATS=no
echo " ====== Generating config  ====== "
/start.py generate
echo " ====== Patching for CI  ====== "
sed -i 's/^#allow_guest_access:.*$/allow_guest_access: true/g' /data/homeserver.yaml
sed -i 's/^#enable_registration_without_verification:.*$/enable_registration_without_verification: true/g' /data/homeserver.yaml
sed -i 's/^#enable_registration:.*$/enable_registration: true/g' /data/homeserver.yaml
echo " ====== Starting server with:  ====== "
cat /data/homeserver.yaml
echo  " ====== STARTING  ====== " 
/start.py run