#!/bin/bash
set -e
export SYNAPSE_SERVER_NAME=localhost
export SYNAPSE_REPORT_STATS=no
echo " ====== Generating config  ====== "
/start.py generate
echo " ====== Patching for local fixes  ====== "
echo """

email:
  smtp_host: localhost
  smtp_port: 1025
  smtp_user: "test"
  smtp_pass: "test"
  force_tls: true
  require_transport_security: true
  enable_tls: true
  notif_from: "Your Friendly %(app)s homeserver <noreply@example.com>"
  app_name: Acter
  enable_notifs: true
  notif_for_new_users: false
  client_base_url: "http://localhost/riot"
  validation_token_lifetime: 15m
  invite_client_location: https://app.element.io
  can_verify_email: true

  subjects:
    message_from_person_in_room: "[%(app)s] You have a message on %(app)s from %(person)s in the %(room)s room..."
    message_from_person: "[%(app)s] You have a message on %(app)s from %(person)s..."
    messages_from_person: "[%(app)s] You have messages on %(app)s from %(person)s..."
    messages_in_room: "[%(app)s] You have messages on %(app)s in the %(room)s room..."
    messages_in_room_and_others: "[%(app)s] You have messages on %(app)s in the %(room)s room and others..."
    messages_from_person_and_others: "[%(app)s] You have messages on %(app)s from %(person)s and others..."
    invite_from_person_to_room: "[%(app)s] %(person)s has invited you to join the %(room)s room on %(app)s..."
    invite_from_person: "[%(app)s] %(person)s has invited you to chat on %(app)s..."
    password_reset: "[%(server_name)s] Password reset"
    email_validation: "[%(server_name)s] Validate your email"

allowed_local_3pids:
  - medium: email
    pattern: '^.*$'

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

modules:
  - module: "synapse_super_invites.SynapseSuperInvites"
    config:
      sql_url: sqlite:///data/super_invites.db
      generate_registration_token: true

""" >>  /data/homeserver.yaml

echo " ====== Starting server with:  ====== "
cat /data/homeserver.yaml
echo  " ====== STARTING  ====== " 
/start.py run