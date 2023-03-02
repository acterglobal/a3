#!/bin/bash
set -e
export SYNAPSE_SERVER_NAME=localhost
export SYNAPSE_REPORT_STATS=no
echo " ====== Generating config  ====== "
/start.py generate
echo " ====== Patching for CI  ====== "
echo """

allow_guest_access: true
enable_registration_without_verification: true
enable_registration: true
suppress_key_server_warning: true

rc_message:
  per_second: 1000
  burst_count: 1000

rc_registration:
  per_second: 1000
  burst_count: 1000

rc_login:
  address:
    per_second: 1000
    burst_count: 1000
  account:
    per_second: 1000
    burst_count: 1000
  failed_attempts:
    per_second: 1000
    burst_count: 1000

rc_admin_redaction:
  per_second: 1000
  burst_count: 1000

rc_joins:
  local:
    per_second: 1000
    burst_count: 1000
  remote:
    per_second: 1000
    burst_count: 1000

rc_3pid_validation:
  per_second: 1000
  burst_count: 1000

rc_invites:
  per_room:
    per_second: 1000
    burst_count: 1000
  per_user:
    per_second: 1000
    burst_count: 1000

""" >>  /data/homeserver.yaml

echo " ====== Starting server with:  ====== "
cat /data/homeserver.yaml
echo  " ====== STARTING  ====== " 
/start.py run