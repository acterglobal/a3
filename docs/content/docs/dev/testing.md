+++
title = "Testing"

weight = 10
template = "docs/page.html"

[extra]
toc = true
top = false
+++

## Unit Tests

### Rust

We are using [regular unit tests as by the Rust Book](https://doc.rust-lang.org/book/ch11-00-testing.html). You can run them with `cargo test` .

_Note_: For async unit test, we are using `tokio` so mark them with `#[tokio:test]` (rather than `#[test]`). Example:

```rust
use anyhow::Result;

#[tokio::test]
async fn testing_my_feature() -> Result<()> {
    // ... test code
    Ok(())
}
```

## Flutter Widget tests

_Note_: We currently don't have proper widget unit tests. So this is mainly here for when we do have them available.

```
cd app
flutter test
```

## Integration Tests

### Infrastructure

You need a fresh [`synapse` matrix backend](https://matrix-org.github.io/synapse/latest/) with a specific configuration. We recommend to use the `test-server` setup we provide in `util/test_server`, that uses `docker-compose` on Linux (so you need `docker` and `docker-compose` on your linux) or puts that into a Vagrant virtual machine on all other platforms.

#### Vagrant Virtual Machine (on Windows & Mac)

If you are not on a Linux machine, please [install vagrant](https://developer.hashicorp.com/vagrant/install) and a corresponding provider (probably [VirtualBox](https://www.virtualbox.org/wiki/Downloads)). Then simply run `cargo make test-server` from the repository root and it will provision the virtual machine and start the synapse matrix backend.

**Alternatives**

<details>
<summary><strong>Local docker-compose</strong></summary>

Alternatively to using the vagrant you can also run the synapse matrix backend with the proper configuration on any Linux base system with docker and docker-compose available. Just `cd utils/test_server` and start the docker-compose in there via `docker-compose up`. Ensure the server is up and available at `http://localhost:8118`.

- **Install docker**

```sh
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt-cache policy docker-ce
sudo apt install docker-ce
sudo systemctl status docker
```

- **Install docker-compose**

You can't use `v1.x.x`, because it doesn't parse `mode` param in `rageshake.volumes.tmpfs`.

```sh
sudo curl -L "https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
```

</details>
<details>
<summary><strong>Using the shared testing servers</strong></summary>

If you are a team member with access to bitwarden, you can also use the staging and testing instances we have set up. They registered with a registration token to prevent unauthorized access, which are also prefixed to each password and thus need to be supplied for running the tests. Currently the following servers are available for testing with mock-data pre-installed, the registration tokens can be found in bitwarden under the same name.

- **`m-1.acter.global`** (`export DEFAULT_HOMESERVER_URL=https://matrix.m-1.acter.global DEFAULT_HOMESERVER_NAME=m-1.acter.global`)
</details>
<details>
<summary><strong>Custom Synapse-Server</strong></summary>

If you can't or don't want to use the docker containers, you'll need a synapse matrix backend with the following settings included (in the `homeserver.yaml`):

```yaml
allow_guest_access: true
enable_registration_without_verification: true
enable_registration: true
registration_shared_secret: "randomly_generated_string"

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
```

and an `admin` account with the username `admin` and passwort `admin` (which you can create with `register_new_matrix_user -u admin -p admin -a -c $HOMESERVER_CONFIG_PATH $HOMESERVER_URL`). To avoid the change of server URL under VMWare, you can use NAT mode not Bridged mode as network.

Please change `bind_addresses` of `listeners` from `['::1', '127.0.0.1']` to `['0.0.0.0']` (in the `homeserver.yaml`), that means any address and allows remote connection (non-localhost).

To avoid the change of server URL under VMWare, you can use NAT mode not Bridged mode as network.

</details>

<details>
<summary><strong>Ubuntu VM Guide under sqlite</strong></summary>

```shell
sudo apt update
sudo apt upgrade

sudo apt install lsb-release wget apt-transport-https

sudo wget -qO /usr/share/keyrings/matrix-org-archive-keyring.gpg https://packages.matrix.org/debian/matrix-org-archive-keyring.gpg

sudo echo "deb [signed-by=/usr/share/keyrings/matrix-org-archive-keyring.gpg] https://packages.matrix.org/debian/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/matrix-org.list

sudo apt update
sudo apt upgrade
sudo apt install matrix-synapse-py3
```

At the end of `sudo apt install matrix-synapse-py3`, you will get the following dialog.

![Ubuntu ServerName](../../../static/images/ubuntu-servername.png)

Keep `localhost` in this dialog, that is domain applied to all users in `acter-test`.
`server_name` in `/etc/matrix-synapse/homeserver.yaml` seems to not affect synapse config and the setting of this dialog during installation affects synapse config clearly.

In `homeserver.yaml`, you have to change `bind_addresses: ['::1', '127.0.0.1']` to `bind_addresses: ['0.0.0.0']`.
And append the following content to `homeserver.yaml`.

```yaml
allow_guest_access: true
enable_registration_without_verification: true
enable_registration: true
registration_shared_secret: "2lyjkU7Ybp24rWR1TBJkut65RFcXZZA"

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
```

Update firewall. But it may not be necessary.

```shell
sudo ufw allow 8008
```

Start synapse service.

```shell
sudo systemctl enable matrix-synapse
sudo systemctl start matrix-synapse
sudo systemctl status matrix-synapse
```

You needn't to add `admin` user with `register_new_matrix_user`.

</details>

<details>
<summary><strong>Ubuntu VM Guide under postgresql</strong></summary>

```shell
sudo apt update
sudo apt upgrade

sudo apt install lsb-release wget apt-transport-https

sudo wget -qO /usr/share/keyrings/matrix-org-archive-keyring.gpg https://packages.matrix.org/debian/matrix-org-archive-keyring.gpg

sudo echo "deb [signed-by=/usr/share/keyrings/matrix-org-archive-keyring.gpg] https://packages.matrix.org/debian/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/matrix-org.list

sudo apt update
sudo apt upgrade
sudo apt install matrix-synapse-py3
```

At the end of `sudo apt install matrix-synapse-py3`, you will get the following dialog.

![Ubuntu ServerName](../../../static/images/ubuntu-servername.png)

Keep `localhost` in this dialog, that is domain applied to all users in `acter-test`.
`server_name` in `homeserver.yaml` seems to not affect synapse config and the setting of this dialog during installation affects synapse config clearly.

In `homeserver.yaml`, you have to change `bind_addresses: ['::1', '127.0.0.1']` to `bind_addresses: ['0.0.0.0']`.
And append the following content to `homeserver.yaml`.

```yaml
allow_guest_access: true
enable_registration_without_verification: true
enable_registration: true
registration_shared_secret: "2lyjkU7Ybp24rWR1TBJkut65RFcXZZA"

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
```

You need to install postgresql.

```shell
sudo apt install postgresql postgresql-contrib

sudo -i -u postgres

psql

CREATE USER "synapseuser" WITH PASSWORD 'Pass';

CREATE DATABASE synapse ENCODING 'UTF8' LC_COLLATE='C' LC_CTYPE='C' template=template0 OWNER "synapseuser";
```

Add the following to `/etc/postgresql/pg_hba.conf`.

```
host    synapse     synapse_user    ::1/128     scram-sha-256
```

Restart postgresql.

```shell
sudo systemctl restart postgresql.service
```

Install psycopg2.

```shell
sudo apt install python3-psycopg2
```

Update the `database` section in `homeserver.yaml`.

```yaml
#database:
#  name: sqlite3
#  args:
#    database: /var/lib/matrix-synapse/homeserver.db
database:
  name: psycopg2
  args:
    user: synapseuser
    password: Pass
    database: synapse
    host: localhost
    cp_min: 5
    cp_max: 10
```

Update firewall.

```shell
sudo ufw allow 8008
```

Start synapse server

```shell
sudo systemctl enable matrix-synapse
sudo systemctl start matrix-synapse
sudo systemctl status matrix-synapse
```

You needn't to add `admin` user with `register_new_matrix_user`.

</details>

#### Firewall

If you are running synapse on a virtual or remote machine and API call is not working, you can update the firewall rules to allow access to the ports. To turn off the public profile of a server firewall on a `Ubuntu` linux, you can use `gufw` and disable it like so:

![Ubuntu Firewall](../../../static/images/ubuntu-firewall.png)

#### Testing the server

Your server should now show the default "welcome" screen when you open the browser at `http://localhost:8118` (or any external address if you changed that).

#### Mock data

The rust integration tests expect a certain set of `mock` data. You can easily get this set up by running

`cargo run -p acter-cli -- mock --homeserver-url $DEFAULT_HOMESERVER_URL --homeserver-name localhost`

**Reset docker**

To start the docker-compose afresh:

1. stop the service with `docker-compose stop`
2. remove the data at `rm -rf .local`
3. start the service with `docker-compose up -d`

**Reset database (in case of SQLite)**

1. Stop service with `sudo systemctl stop matrix-synapse`
2. Delete this file `/var/lib/matrix-synapse/homeserver.db`
3. Start service with `sudo systemctl start matrix-synapse`
4. Run this command `cargo run -p acter-cli -- mock --homeserver-url $DEFAULT_HOMESERVER_URL --homeserver-name localhost`

Don't forget to rerun the `mock data` generation again.

**Reset database (in case of PostgreSQL)**

1. Stop service with `sudo systemctl stop matrix-synapse`
2. Delete and recreate the database

```
sudo su - postgres
psql
DROP DATABASE synapse;
CREATE DATABASE synapse ENCODING 'UTF8' LC_COLLATE='C' LC_CTYPE='C' template=template0 OWNER "synapseuser";
\q
```

3. Start service with `sudo systemctl start matrix-synapse`
4. Run this command `cargo run -p acter-cli mock --homeserver-url http://192.168.142.130:8008 --homeserver-name ds9.acter.global`

This server name must be the same as one in `/etc/matrix-synapse/conf.d/server_name.yaml`.

#### Email config

We will use `mailhog` as local mail server for authentication.
Probably `mailtutan` may be good choice, but it is dummy server that doesn't respond a request from `synapse`.
`synapse` is pending if there is no reply from mail server.

1. Clone & prepare to run `mailhog`

```
git clone https://github.com/mailhog/MailHog.git
go mod vendor
```

2. Create `auth.txt` file in root of `mailhog` project and enter lines of `username:password` for basic authentication of mail sender (`test1`) & receiver (`test2`), where password is `test` wrapped by `bcrypt`

```
test1:$2a$04$qxRo.ftFoNep7ld/5jfKtuBTnGqff/fZVyj53mUC5sVf9dtDLAi/S
test2:$2a$04$qxRo.ftFoNep7ld/5jfKtuBTnGqff/fZVyj53mUC5sVf9dtDLAi/S
```

3. Run `mailhog` with specified auth file

```
MH_AUTH_FILE="auth.txt" go run .
```

Provided that username is `test2` and password is `test`, you can access `http://localhost:8025` to view maillist of `test2`.

4. Insert the following config to `homeserver.yaml`

```yaml
email:
  smtp_host: localhost
  smtp_port: 1025
  smtp_user: "test1"
  smtp_pass: "test"
  force_tls: false
  require_transport_security: false
  enable_tls: false
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
```

Here `force_tls/require_transport_security/enable_tls` should be `false` as `mailhog` doesn't support TLS properly.
And `can_verify_email` should be set because `synapse` uses it.

5. Restart `synapse`

When you run tests (ex: `auth::can_register_via_email` or `auth::can_reset_password_via_email`) related with authentication via email, you can see `test2` receives email from `noreply@example.com`.

**One-time use of email address for password reset**

Once an email address is used to authenticate in password reset, it is bound to that account.
It can't be used again for another account.
You have to use another email address.
If you want, you can reset database because binding info is stored there.

### Rust integration tests

To run the rust integration tests, you need a fresh integration testing infrastructure (see above) available at `$DEFAULT_HOMESERVER_URL`. Assuming you are running the docker-compose setup, this would be `http://localhost:8118` (which is the fallback default, so you don't have to put it into your environment). Then you can run the integration test with:

<details><summary><strong>Custom Environment variable under Windows PowerShell</strong></summary>

You can set up environment variable for `cargo` as following (assuming the server is accessible at `10.0.0.1:8008` and log level is `info`):

```bash
$env:DEFAULT_HOMESERVER_URL="http://10.0.0.1:8008"; $env:RUST_LOG="info"; cargo test -p acter-test -- --nocapture
```

</details>

<details><summary><strong>Custom Environment variable under Linux Shell</strong></summary>

You can set up environment variable for `cargo` as following (assuming the server is available at `10.0.0.1:8008` and log level is `warn`):

```bash
DEFAULT_HOMESERVER_URL="http://10.0.0.1:8008" RUST_LOG="warn" cargo test -p acter-test -- --nocapture
```

</details>

### Flutter UI integration tests

We are using `convenient_tests` framework to build and run flutter integration tests. The default test target is an Android Emulator. You need the above mentioned backend setup

#### Running with the Manager

You can easily run the test manager by preparing everything for the target you want to test on (e.g. start the android-emulator, build `cargo make android-dev`) and then start the test-server and test-manager app by running `cargo make ui-tester`. While leaving this open, in a second terminal start the app in ui test mode via `cargo make ui-test-app-android-emulator` (for the android-emulator version or `cargo make ui-test-app-local` for the local desktop app). You can now reconnect from the manager UI and run the specific tests

**Alternatives**

<details>
<summary><strong>Running them manually without cargo-make</string></summary>

**Requirements**:

- To run the rust integration tests, you need a fresh integration testing infrastructure (see above) available at `$DEFAULT_HOMESERVER_URL` with the `$DEFAULT_HOMESERVER_NAME` set.
- Have your test target ready: build the latest rust-sdk for it (e.g. `cargo make android-dev`), and have the emulator up and running

To the run the tests from the interactive manager UI, you can start both the test-server and the manager by running `cargo make ui-tester` from the repo root (or manually run the `cd util/conv_test_man && flutter run` (`-d linux` / `-d macos` / `-d windows` for whichever is your desktop host), then from the `app` folder run the integration test version of the app by running:

```
    flutter run integration_test/main_test.dart --host-vmservice-port 9753 --disable-service-auth-codes --dart-define CONVENIENT_TEST_APP_CODE_DIR=lib --dart-define DEFAULT_HOMESERVER_URL=$DEFAULT_HOMESERVER_URL --dart-define DEFAULT_HOMESERVER_NAME=$DEFAULT_HOMESERVER_NAME
```

if you are running it with the Android emulator and have the server exposed on 8118 on your localhost, you need point the urls to `10.0.2.2` and also expose the `CONVENIENT_TEST_MANAGER_HOST`
IP as follows:

```
    flutter run integration_test/main_test.dart --host-vmservice-port 9753 --disable-service-auth-codes --dart-define CONVENIENT_TEST_APP_CODE_DIR=lib --dart-define CONVENIENT_TEST_MANAGER_HOST=10.0.2.2 --dart-define DEFAULT_HOMESERVER_URL=http:/10.0.2.2:8118/ --dart-define DEFAULT_HOMESERVER_NAME=localhost
```

Once the app is up and ready click "reconnect" in the manager and then you can select the tests you want to run.

</details>

<details>
<summary><strong>Running from the entire suite from cli</strong></summary>

**Requirements**:

- To run the rust integration tests, you need a fresh integration testing infrastructure (see above) available at `$DEFAULT_HOMESERVER_URL` with the `$DEFAULT_HOMESERVER_NAME` set.
- Have your test target ready: build the latest rust-sdk for it (e.g. `cargo make android-dev`), and have the emulator up and running

From the `app` folder run the integration test version of the app by running:

```
    flutter run integration_test/main_test.dart --host-vmservice-port 9753 --disable-service-auth-codes --dart-define CONVENIENT_TEST_APP_CODE_DIR=lib --dart-define DEFAULT_HOMESERVER_URL=$DEFAULT_HOMESERVER_URL --dart-define DEFAULT_HOMESERVER_NAME=$DEFAULT_HOMESERVER_NAME
```

if you are running it with the Android emulator and have the server exposed on 8118 on your localhost, you need point the urls to `10.0.2.2` and also expose the `CONVENIENT_TEST_MANAGER_HOST` IP as follows:

```
    flutter run integration_test/main_test.dart --host-vmservice-port 9753 --disable-service-auth-codes --dart-define CONVENIENT_TEST_APP_CODE_DIR=lib --dart-define CONVENIENT_TEST_MANAGER_HOST=10.0.2.2 --dart-define DEFAULT_HOMESERVER_URL=http:/10.0.2.2:8118/ --dart-define DEFAULT_HOMESERVER_NAME=localhost
```

Once ready, start the automatic full cli-runner by running (from `/app`):

```
dart run convenient_test_manager_dart --enable-report-saver
```

That will create a folder with the entire report in your `$TMPFOLDER/ConvenientTest/`

</details>

**From Visual Studio Code**

If you have the [Flutter extension for vscode](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter) you can also run the `Run Integration Tests (acter)` launch commend from within your VSCode to run the tests directly or use the `Run Local Integration Tests` on the specific test from within your editor. To **debug** an integration tests, use the `Debug Integration Tests (acter)` on the specific test from within the editor - which allows you to add breakpoints and debugging widgets as usual:

![](../../../static/images/integration-tests-debug-vscode-example.png)
