#!/bin/bash
set -e
if [ ! -f /data/homeserver.yaml ]; then
  export SYNAPSE_SERVER_NAME=localhost
  export SYNAPSE_REPORT_STATS=no
  echo " ====== Generating config  ====== "
  /start.py generate
  echo " ====== Patching for local fixes  ====== "
  echo cat /data/homeserver.local.yaml >>  /data/homeserver.yaml
  echo " ====== Starting server with:  ====== "
  cat /data/homeserver.yaml
else
  echo "Configuration already exists, ignoring"
fi;
echo  " ====== STARTING  ====== " 
/start.py run