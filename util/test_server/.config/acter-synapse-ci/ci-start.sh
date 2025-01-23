#!/bin/bash
set -e
export SYNAPSE_SERVER_NAME=localhost
export SYNAPSE_LOG_LEVEL=DEBUG
export SYNAPSE_LOG_SENSITIVE=true
export SYNAPSE_LOG_TESTING=true
export SYNAPSE_REPORT_STATS=no
echo " ====== Generating config  ====== "
/start.py generate
echo " ====== Patching for local fixes  ====== "
echo """

email:
  smtp_host: mailhog
  smtp_port: 1025
  force_tls: false
  require_transport_security: false
  enable_tls: false
  notif_from: \"Your Friendly %(app)s homeserver <noreply@acter.global>\"
  can_verify_email: true

allow_guest_access: true
enable_registration_without_verification: true
enable_registration: true
suppress_key_server_warning: true

experimental_features:
  msc3266_enabled: true
  msc3575_enabled: true
  msc4186_enabled: true

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

modules:
  - module: \"synapse_super_invites.SynapseSuperInvites\"
    config:
      sql_url: sqlite:///data/super_invites.db
      generate_registration_token: true
      share_link_generator:
        url_prefix: http://localhost:8099/
        target_path: /share_links/

""" >>  /data/homeserver.yaml

echo " ====== Starting server with:  ====== "
cat /data/homeserver.yaml
echo  " ====== STARTING  ====== " 
/start.py run