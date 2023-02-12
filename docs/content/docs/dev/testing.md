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

## Flutter

_Note_: We currently don't have proper widget unit tests. So this is mainly here for when we do have them available.

```
cd app
flutter test
```


## Integration Tests

### Infrastructure

You need a fresh [`synapse` matrix backend](https://matrix-org.github.io/synapse/latest/) with a specific configuration. We recommend to just use our docker-compose setup for that:

#### Docker Container
We have a `docker` container image available with that setup already for you at `lightyear/effektio-synapse-ci:latest`. Easiest is to use `docker-compose up -d` to run it locally from the root directory. This will also create the necessary `admin` account.


<details>
<summary><strong>Custom Synapse-Server</strong></summary>

If you can't or don't want to use the docekr containers, you'll need a synapse matrix backend with the following settings included (in the `homeserver.yaml`):

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

![Ubuntu ServerName](/images/ubuntu-servername.png)

You have to enter `ds9.effektio.org` in this dialog, that is domain applied to all users in `effektio-test`.
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

![Ubuntu Firewall](/images/ubuntu-firewall.png)

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

![Ubuntu ServerName](/images/ubuntu-servername.png)

You have to enter `ds9.effektio.org` in this dialog, that is domain applied to all users in `effektio-test`.
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

![Ubuntu Firewall](/images/ubuntu-firewall.png)

</details>

#### Mock data
The integration tests expect a certain set of `mock` data. You can easily get this set up by running

`cargo run -p effektio-cli -- mock $HOMESERVER`

**Reset docker**
To start the docker-compose afresh:

1. stop the service with `docker-compose stop`
2. remove the data at `rm -rf .local`
3. start the service with `docker-compose up -d`

**Reset database (in case of SQLite)**
1. Stop service with `sudo systemctl stop matrix-synapse`
2. Delete this file `/var/lib/matrix-synapse/homeserver.db`
3. Start service with `sudo systemctl start matrix-synapse`
4. Run this command `cargo run -p effektio-cli -- mock $HOMESERVER`

Don't forget to rerun the `mock data` generation again.

### Rust integration tests

To run the rust integration tests, you need a fresh integration testing infrastructure (see above) availabe at `$HOMESERVER`. Assuming you are running the docker-compose setup, this would be `http://localhost:8118` (which is the fallback default, so you don't have to put it into your environment). Then you can run the integration test with:

<details><summary><strong>Custom Environment variable under Windows PowerShell</strong></summary>

You can set up environment variable for `cargo` as following (assuming the server is accessible at `10.0.0.1:8008` and log level is `info`):

```bash
$env:HOMESERVER="http://10.0.0.1:8008"; $env:RUST_LOG="info"; cargo test -p effektio-test -- --nocapture
```

</details>

<details><summary><strong>Custom Environment variable under Linux Shell</strong></summary>

You can set up environment variable for `cargo` as following (assuming the server is available at `10.0.0.1:8008` and log level is `warn`):

```bash
HOMESERVER="http://10.0.0.1:8008" RUST_LOG="warn" cargo test -p effektio-test -- --nocapture
```

</details>

### Flutter UI integration tests

Flutter integration tests can be found `app/integration_test`.

**Running**

To run the rust integration tests, you need a fresh integration testing infrastructure (see above) availabe at `$HOMESERVER`. The following will build the App and run the tests with on the default target (or you specify it via `-d`, e.g. `-d linux` or `-d windows`).

```
cd app
flutter test integration_test/* --dart-define DEFAULT_EFFEKTIO_SERVER=$HOMESERVER --dart-define DEFAULT_EFFEKTIO_DOMAIN=ds9.effektio.org
```

**From Visual Studio Ccode**

If you have the [Flutter extension for vscode](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter) you can also run the `Run Integration Tests (effektio)` launch commend from within your VSCode to run the tests directly or use the `Run Local Integration Tests` on the specific test from within your editor. To **debug** an integration tests, use the `Debug Integration Tests (effektio)` on the specific test from within the editor - which allows you to add breakpoints and debugging widgets as usual:

![](/images/integration-tests-debug-vscode-example.png)