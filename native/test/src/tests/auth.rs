use acter::{
    api::{
        change_password_without_login, fetch_session_for_password_change, guest_client,
        login_new_client, login_new_client_under_config, login_with_token_under_config,
        make_client_config, request_password_change_email_token,
        request_registration_token_via_email,
    },
    matrix_sdk::reqwest::Client,
};
use anyhow::{bail, Context, Result};
use mail_parser::MessageParser;
use mailhog_rs::{ListMessagesParams, MailHog};
use regex::Regex;
use std::collections::HashMap;
use tempfile::TempDir;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};
use tracing::{info, warn};
use uuid::Uuid;

use crate::utils::{default_user_password, login_test_user, random_user};

#[tokio::test]
async fn guest_can_login() -> Result<()> {
    let _ = env_logger::try_init();
    let should_test = option_env!("GUEST_ACCESS").unwrap_or("false");
    if should_test == "1" || should_test == "true" {
        let homeserver_name = option_env!("DEFAULT_HOMESERVER_NAME")
            .unwrap_or("localhost")
            .to_string();
        let homeserver_url = option_env!("DEFAULT_HOMESERVER_URL")
            .unwrap_or("http://localhost:8118")
            .to_string();

        let tmp_dir = TempDir::new()?;
        let _client = guest_client(
            tmp_dir.path().to_string_lossy().to_string(),
            tmp_dir.path().to_string_lossy().to_string(),
            homeserver_name,
            homeserver_url,
            Some("GUEST_DEV".to_string()),
        )
        .await?;
    } else {
        warn!("Skipping guest test. To run set env var GUEST_ACCESS=1");
    }
    Ok(())
}

#[tokio::test]
async fn sisko_can_login() -> Result<()> {
    let _ = env_logger::try_init();
    let homeserver_name = option_env!("DEFAULT_HOMESERVER_NAME")
        .unwrap_or("localhost")
        .to_string();
    let homeserver_url = option_env!("DEFAULT_HOMESERVER_URL")
        .unwrap_or("http://localhost:8118")
        .to_string();

    let tmp_dir = TempDir::new()?;
    let _client = login_new_client(
        tmp_dir.path().to_string_lossy().to_string(),
        tmp_dir.path().to_string_lossy().to_string(),
        "@sisko".to_string(),
        default_user_password("sisko"),
        homeserver_name,
        homeserver_url,
        Some("SISKO_DEV".to_string()),
    )
    .await?;
    Ok(())
}

#[tokio::test]
async fn kyra_can_login() -> Result<()> {
    let _ = env_logger::try_init();
    let tmp_dir = TempDir::new()?;
    let homeserver_name = option_env!("DEFAULT_HOMESERVER_NAME")
        .unwrap_or("localhost")
        .to_string();
    let homeserver_url = option_env!("DEFAULT_HOMESERVER_URL")
        .unwrap_or("http://localhost:8118")
        .to_string();

    let _client = login_new_client(
        tmp_dir.path().to_string_lossy().to_string(),
        tmp_dir.path().to_string_lossy().to_string(),
        "@kyra".to_string(),
        default_user_password("kyra"),
        homeserver_name,
        homeserver_url,
        Some("KYRA_DEV".to_string()),
    )
    .await?;
    Ok(())
}

#[tokio::test]
async fn kyra_can_restore() -> Result<()> {
    let _ = env_logger::try_init();
    let homeserver_name = option_env!("DEFAULT_HOMESERVER_NAME")
        .unwrap_or("localhost")
        .to_string();
    let homeserver_url = option_env!("DEFAULT_HOMESERVER_URL")
        .unwrap_or("http://localhost:8118")
        .to_string();
    let base_dir = TempDir::new()?;
    let media_dir = TempDir::new()?;
    let (config, user_id) = make_client_config(
        base_dir.path().to_string_lossy().to_string(),
        "@kyra",
        media_dir.path().to_string_lossy().to_string(),
        None,
        &homeserver_name,
        &homeserver_url,
        true,
    )
    .await?;

    let (token, user_id) = {
        let client = login_new_client_under_config(
            config.clone(),
            user_id,
            default_user_password("kyra"),
            None,
            Some("KYRA_DEV".to_string()),
        )
        .await?;
        let token = client.restore_token().await?;
        let user_id = client
            .user_id()
            .expect("username missing after login. weird");
        (serde_json::from_str(&token)?, user_id)
    };

    let client = login_with_token_under_config(token, config).await?;
    let uid = client
        .user_id()
        .expect("Login by token seems to be not working");
    assert_eq!(uid, user_id);
    Ok(())
}

#[tokio::test]
async fn kyra_can_restore_with_db_passphrase() -> Result<()> {
    let _ = env_logger::try_init();
    let homeserver_name = option_env!("DEFAULT_HOMESERVER_NAME")
        .unwrap_or("localhost")
        .to_string();
    let homeserver_url = option_env!("DEFAULT_HOMESERVER_URL")
        .unwrap_or("http://localhost:8118")
        .to_string();
    let base_dir = TempDir::new()?;
    let media_dir = TempDir::new()?;
    let db_passphrase = Uuid::new_v4().to_string();
    let (config, user_id) = make_client_config(
        base_dir.path().to_string_lossy().to_string(),
        "@kyra",
        media_dir.path().to_string_lossy().to_string(),
        Some(db_passphrase.clone()),
        &homeserver_name,
        &homeserver_url,
        true,
    )
    .await?;

    let (token, user_id) = {
        let client = login_new_client_under_config(
            config.clone(),
            user_id,
            default_user_password("kyra"),
            Some(db_passphrase),
            Some("KYRA_DEV".to_string()),
        )
        .await?;
        let token = client.restore_token().await?;
        let user_id = client
            .user_id()
            .expect("username missing after login. weird");
        (serde_json::from_str(&token)?, user_id)
    };

    let client = login_with_token_under_config(token, config).await?;
    let uid = client
        .user_id()
        .expect("Login by token with db_passphrase seems to be not working");
    assert_eq!(uid, user_id);
    Ok(())
}

#[tokio::test]
async fn can_deactivate_user() -> Result<()> {
    let _ = env_logger::try_init();
    let username = {
        let client = random_user("deactivate_me").await?;
        // password in tests can be figured out from the username
        let username = client.user_id().expect("we just logged in");
        let password = default_user_password(username.localpart());
        print!("with password: {password}");
        assert!(client.deactivate(password).await?, "deactivation failed");
        username
    };

    // now trying to login or should fail as the user has been deactivated
    // and registration is blocked because it is in use.

    assert!(
        login_test_user(username.localpart().to_string())
            .await
            .is_err(),
        "Was still able to login or register that username"
    );
    Ok(())
}

#[tokio::test]
async fn user_changes_password() -> Result<()> {
    let _ = env_logger::try_init();

    let mut client = random_user("change_password").await?;
    let user_id = client.user_id().expect("we just logged in");
    let password = default_user_password(user_id.localpart());
    let new_password = format!("new_{:?}", password.as_str());

    let result = client
        .clone()
        .change_password(password.clone(), new_password.clone())
        .await?;
    assert!(result, "Couldn't change password successfully");

    let result = client.logout().await?;
    assert!(result, "Couldn't logout successfully");

    let base_dir = TempDir::new()?;
    let media_dir = TempDir::new()?;
    let (config, uid) = make_client_config(
        base_dir.path().to_string_lossy().to_string(),
        user_id.localpart(),
        media_dir.path().to_string_lossy().to_string(),
        None,
        option_env!("DEFAULT_HOMESERVER_NAME").unwrap_or("localhost"),
        option_env!("DEFAULT_HOMESERVER_URL").unwrap_or("http://localhost:8118"),
        true,
    )
    .await?;

    let old_pswd_res =
        login_new_client_under_config(config.clone(), uid.clone(), password, None, None).await;
    assert!(old_pswd_res.is_err(), "Can't login with old password");

    let new_pswd_res = login_new_client_under_config(config, uid, new_password, None, None).await;
    assert!(
        new_pswd_res.is_ok(),
        "Should be able to login with new password"
    );
    Ok(())
}

#[tokio::test]
async fn can_register_via_email() -> Result<()> {
    let _ = env_logger::try_init();

    let base_dir = TempDir::new()?;
    let media_dir = TempDir::new()?;
    let prefix = "reset_password".to_owned();
    let uuid = Uuid::new_v4().to_string();
    let email = "test2@localhost".to_owned();

    let resp = request_registration_token_via_email(
        base_dir.path().to_string_lossy().to_string(),
        media_dir.path().to_string_lossy().to_string(),
        format!("it-{prefix}-{uuid}"),
        option_env!("DEFAULT_HOMESERVER_NAME")
            .unwrap_or("localhost")
            .to_owned(),
        option_env!("DEFAULT_HOMESERVER_URL")
            .unwrap_or("http://localhost:8118")
            .to_owned(),
        email,
    )
    .await?;

    info!("registration token via email - sid: {}", resp.sid());
    info!(
        "registration token via email - submit_url: {:?}",
        resp.submit_url().text(),
    );

    read_email_msg("test2", "test", "_matrix/client/unstable/registration").await?;

    Ok(())
}

#[tokio::test]
async fn can_reset_password_via_email_with_login() -> Result<()> {
    let _ = env_logger::try_init();

    let mut client = random_user("reset_password_with_login").await?;
    let user_id = client.user_id().expect("we just logged in");
    let username = user_id.localpart();
    let old_pswd = default_user_password(username);
    let account = client.account()?;
    let resp = account
        .request_3pid_email_token("test3@localhost".to_owned())
        .await?;
    let client_secret = resp.client_secret();
    let sid = resp.sid();

    read_email_msg("test3", "test", "_matrix/client/unstable/add_threepid").await?;

    account
        .add_3pid(client_secret, sid, old_pswd.clone())
        .await?;

    let homeserver_name = option_env!("DEFAULT_HOMESERVER_NAME").unwrap_or("localhost");
    let homeserver_url = option_env!("DEFAULT_HOMESERVER_URL").unwrap_or("http://localhost:8118");
    let email = "test3@localhost".to_owned();

    let resp = request_password_change_email_token(homeserver_url.to_owned(), email).await?; // here m.login.email.identity is started

    info!("password change token via email - sid: {}", resp.sid());
    info!(
        "password change token via email - submit_url: {:?}",
        resp.submit_url().text(),
    );

    let (_token, _client_secret, _sid) =
        confirm_email_msg("test3", "test", "_synapse/client/password_reset").await?; // here m.login.email.identity is completed
    let new_pswd = format!("new_{}", &old_pswd);

    account
        .change_password(old_pswd.clone(), new_pswd.clone())
        .await?;

    client.logout().await?;

    let base_dir = TempDir::new()?;
    let media_dir = TempDir::new()?;
    let res = login_new_client(
        base_dir.path().to_string_lossy().to_string(),
        media_dir.path().to_string_lossy().to_string(),
        username.to_string(),
        old_pswd,
        homeserver_name.to_string(),
        homeserver_url.to_string(),
        None,
    )
    .await;

    assert!(res.is_err(), "old password should be unavailable now");

    let base_dir = TempDir::new()?;
    let media_dir = TempDir::new()?;
    let res = login_new_client(
        base_dir.path().to_string_lossy().to_string(),
        media_dir.path().to_string_lossy().to_string(),
        username.to_string(),
        new_pswd,
        homeserver_name.to_string(),
        homeserver_url.to_string(),
        None,
    )
    .await;

    assert!(res.is_ok(), "new password should be available now");

    Ok(())
}

#[tokio::test]
async fn can_reset_password_via_email_without_login() -> Result<()> {
    let _ = env_logger::try_init();

    let mut client = random_user("reset_password_without_login").await?;
    let user_id = client.user_id().expect("we just logged in");
    let username = user_id.localpart();
    let old_pswd = default_user_password(username);
    let account = client.account()?;
    let resp = account
        .request_3pid_email_token("test4@localhost".to_owned())
        .await?;
    let client_secret = resp.client_secret();
    let sid = resp.sid();

    read_email_msg("test4", "test", "_matrix/client/unstable/add_threepid").await?;

    account
        .add_3pid(client_secret, sid, old_pswd.clone())
        .await?;

    client.logout().await?;

    let homeserver_name = option_env!("DEFAULT_HOMESERVER_NAME").unwrap_or("localhost");
    let homeserver_url = option_env!("DEFAULT_HOMESERVER_URL").unwrap_or("http://localhost:8118");
    let email = "test4@localhost".to_owned();

    let resp = request_password_change_email_token(homeserver_url.to_owned(), email).await?; // here m.login.email.identity is started

    info!("password change token via email - sid: {}", resp.sid());
    info!(
        "password change token via email - submit_url: {:?}",
        resp.submit_url().text(),
    );

    let resp = fetch_session_for_password_change(homeserver_url).await?;
    let session = resp.session();

    let (token, client_secret, sid) =
        confirm_email_msg("test4", "test", "_synapse/client/password_reset").await?; // here m.login.email.identity is completed
    let new_pswd = format!("new_{}", &old_pswd);

    change_password_without_login(
        homeserver_url,
        &new_pswd,
        sid,
        client_secret,
        "localhost".to_owned(),
        token,
        session,
    )
    .await?;

    // account
    //     .change_password(old_pswd.clone(), new_pswd.clone())
    //     .await?;

    let base_dir = TempDir::new()?;
    let media_dir = TempDir::new()?;
    let res = login_new_client(
        base_dir.path().to_string_lossy().to_string(),
        media_dir.path().to_string_lossy().to_string(),
        username.to_string(),
        old_pswd,
        homeserver_name.to_string(),
        homeserver_url.to_string(),
        None,
    )
    .await;

    assert!(res.is_err(), "old password should be unavailable now");

    let base_dir = TempDir::new()?;
    let media_dir = TempDir::new()?;
    let res = login_new_client(
        base_dir.path().to_string_lossy().to_string(),
        media_dir.path().to_string_lossy().to_string(),
        username.to_string(),
        new_pswd,
        homeserver_name.to_string(),
        homeserver_url.to_string(),
        None,
    )
    .await;

    assert!(res.is_ok(), "new password should be available now");

    Ok(())
}

async fn read_email_msg(user: &str, pswd: &str, dir: &str) -> Result<(String, String, String)> {
    let base_url = format!("http://{}:{}@localhost:8025", user, pswd); // url should include authorization
    let mailhog = MailHog::new(base_url);
    let params = ListMessagesParams {
        start: None,
        limit: None,
    };

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let mailhog_cl = mailhog.clone();
    let params_cl = params.clone();
    Retry::spawn(retry_strategy, move || {
        let mailhog = mailhog_cl.clone();
        let params = params_cl.clone();
        async move {
            let msg_list = mailhog.list_messages(params).await?;
            if msg_list.count == 0 {
                bail!("email msg not found");
            }
            Ok(())
        }
    })
    .await?;

    let msg_list = mailhog.list_messages(params).await?;
    let latest_msg = msg_list
        .items
        .first()
        .context("User should receive at least a mail msg")?;

    info!("last msg content headers: {:?}", latest_msg.content.headers);
    info!("last msg content body: {:?}", latest_msg.content.body);
    info!("last msg created: {:?}", latest_msg.created);
    info!("last msg from: {:?}", latest_msg.from);
    info!("last msg id: {:?}", latest_msg.id);

    let mut headers = vec![];
    for (key, vals) in latest_msg.content.headers.iter() {
        for (pos, val) in vals.iter().enumerate() {
            if pos == 0 {
                headers.push(format!("{key}: {val}"));
            } else {
                headers.push(val.clone());
            }
        }
    }
    let content = format!(
        "{}\r\n\r\n{}",
        headers.join("\r\n"),
        latest_msg.content.body,
    );
    let mail_msg = MessageParser::default()
        .parse(&content)
        .context("mail content should be parsed")?;
    let plain_body = mail_msg
        .body_text(0)
        .context("plain text should be extracted")?
        .to_string();

    info!("plain body: {}", plain_body);

    // starts with "https://localhost" on local synapse
    // starts with "http://localhost:8118" on github actions workflow
    // FIXME: these 2 prefixes can be unified into one, if something is modified in email config of homeserver.yaml???
    let pattern = format!(
        r"(?m)^.*(https://localhost|http://localhost:8118)/{}/email/submit_token\?token=(.*)&client_secret=(.*)&sid=(.*)\n.*$",
        dir
    );
    let re = Regex::new(&pattern)?;
    let err = format!("should capture url: {}", &plain_body);
    let caps = re.captures(&plain_body).context(err)?;

    let token = caps.get(2).map_or("", |m| m.as_str());
    let client_secret = caps.get(3).map_or("", |m| m.as_str());
    let sid = caps.get(4).map_or("", |m| m.as_str());

    info!("token: {}", token);
    info!("client secret: {}", client_secret);
    info!("session id: {}", sid);

    let client = Client::new();
    let submit_url = format!("http://localhost:8118/{}/email/submit_token", dir);
    let params = [
        ("token", token),
        ("client_secret", client_secret),
        ("sid", sid),
    ];
    let req = client.get(submit_url).query(&params).build()?;
    let _resp = client.execute(req).await?.error_for_status()?;

    Ok((token.to_owned(), client_secret.to_owned(), sid.to_owned()))
}

async fn confirm_email_msg(user: &str, pswd: &str, dir: &str) -> Result<(String, String, String)> {
    let (token, client_secret, sid) = read_email_msg(user, pswd, dir).await?;

    let client = Client::new();
    let submit_url = format!("http://localhost:8118/{}/email/submit_token", dir);
    let mut params = HashMap::new();
    params.insert("token", token.clone());
    params.insert("client_secret", client_secret.clone());
    params.insert("sid", sid.clone());
    let req = client.post(submit_url).form(&params).build()?;
    let _resp = client.execute(req).await?.error_for_status()?;

    Ok((token, client_secret, sid))
}
