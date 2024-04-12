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

#### Firewall

If you are running synapse on a virtual or remote machine and API call is not working, you can update the firewall rules to allow access to the ports. To turn off the public profile of a server firewall on a `Ubuntu` linux, you can use `gufw` and disable it like so:

![Ubuntu Firewall](../../../static/images/ubuntu-firewall.png)

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

#### Firewall

If you are running synapse on a virtual or remote machine and API call is not working, you can update the firewall rules to allow access to the ports. To turn off the public profile of a server firewall on a `Ubuntu` linux, you can use `gufw` and disable it like so:

![Ubuntu Firewall](../../../static/images/ubuntu-firewall.png)

</details>

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
