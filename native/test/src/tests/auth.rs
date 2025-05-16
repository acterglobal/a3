use acter::api::{
    guest_client, login_new_client, login_new_client_under_config, login_with_token_under_config,
    make_client_config, request_password_change_token_via_email,
    request_registration_token_via_email, reset_password,
};
use anyhow::{bail, Context, Result};
use mail_parser::MessageParser;
use mailhog_rs::{MailHog, MessageList, SearchKind, SearchParams};
use matrix_sdk::reqwest::{Client as ReqClient, Response as ReqResponse};
use regex::Regex;
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
            .to_owned();
        let homeserver_url = option_env!("DEFAULT_HOMESERVER_URL")
            .unwrap_or("http://localhost:8118")
            .to_owned();

        let tmp_dir = TempDir::new()?;
        let _client = guest_client(
            tmp_dir.path().to_string_lossy().to_string(),
            tmp_dir.path().to_string_lossy().to_string(),
            homeserver_name,
            homeserver_url,
            Some("GUEST_DEV".to_owned()),
        )
        .await?;
    } else {
        warn!("Skipping guest test. To run set env var GUEST_ACCESS=1");
    }
    Ok(())
}

#[tokio::test]
async fn user_can_login() -> Result<()> {
    let _ = env_logger::try_init();
    let sisko = random_user("sisko").await?;
    let user_id = sisko.user_id()?;
    let username = user_id.localpart();

    let tmp_dir = TempDir::new()?;
    let _client = login_new_client(
        tmp_dir.path().to_string_lossy().to_string(),
        tmp_dir.path().to_string_lossy().to_string(),
        username.to_owned(),
        default_user_password(username),
        option_env!("DEFAULT_HOMESERVER_NAME")
            .unwrap_or("localhost")
            .to_owned(),
        option_env!("DEFAULT_HOMESERVER_URL")
            .unwrap_or("http://localhost:8118")
            .to_owned(),
        Some("SISKO_DEV".to_owned()),
    )
    .await?;
    Ok(())
}

#[tokio::test]
async fn user_can_restore() -> Result<()> {
    let _ = env_logger::try_init();

    let kyra = random_user("kyra").await?;
    let user_id = kyra.user_id()?;
    let username = user_id.localpart();

    let homeserver_name = option_env!("DEFAULT_HOMESERVER_NAME")
        .unwrap_or("localhost")
        .to_owned();
    let homeserver_url = option_env!("DEFAULT_HOMESERVER_URL")
        .unwrap_or("http://localhost:8118")
        .to_owned();
    let base_dir = TempDir::new()?;
    let media_dir = TempDir::new()?;
    let (config, user_id) = make_client_config(
        base_dir.path().to_string_lossy().to_string(),
        username,
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
            user_id.to_owned(),
            default_user_password(username),
            None,
            Some("KYRA_DEV".to_owned()),
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

    let kyra = random_user("kyra2").await?;
    let user_id = kyra.user_id()?;
    let username = user_id.localpart();

    let homeserver_name = option_env!("DEFAULT_HOMESERVER_NAME")
        .unwrap_or("localhost")
        .to_owned();
    let homeserver_url = option_env!("DEFAULT_HOMESERVER_URL")
        .unwrap_or("http://localhost:8118")
        .to_owned();
    let base_dir = TempDir::new()?;
    let media_dir = TempDir::new()?;
    let db_passphrase = Uuid::new_v4().to_string();
    let (config, user_id) = make_client_config(
        base_dir.path().to_string_lossy().to_string(),
        username,
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
            default_user_password(username),
            Some(db_passphrase),
            Some("KYRA_DEV".to_owned()),
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
        let account = client.account()?;
        // password in tests can be figured out from the username
        let username = client.user_id().expect("we just logged in");
        let password = default_user_password(username.localpart());
        print!("with password: {password}");
        assert!(account.deactivate(password).await?, "deactivation failed");
        username
    };

    // now trying to login or should fail as the user has been deactivated
    // and registration is blocked because it is in use.

    assert!(
        login_test_user(username.localpart().to_owned())
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
    let account = client.account()?;
    let user_id = client.user_id().expect("we just logged in");
    let password = default_user_password(user_id.localpart());
    let new_password = format!("new_{:?}", password);

    let result = account
        .change_password(password.clone(), new_password.clone())
        .await?;
    assert!(result, "Couldn’t change password successfully");

    let result = client.logout().await?;
    assert!(result, "Couldn’t logout successfully");

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
    assert!(old_pswd_res.is_err(), "Can’t login with old password");

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
    let prefix = "register_via_email".to_owned();
    let uuid = Uuid::new_v4().to_string();
    let email = format!("{uuid}@example.org");

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
        email.clone(),
    )
    .await?;

    info!("registration token via email - sid: {}", resp.sid());
    info!(
        "registration token via email - submit_url: {:?}",
        resp.submit_url(),
    );

    confirm_email_msg(email, "_matrix/client/unstable/registration").await?;

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
    let email = format!("{username}@example.org");
    let resp = account
        .request_3pid_management_token_via_email(email.clone())
        .await?;
    let client_secret = resp.client_secret();
    let sid = resp.sid();

    confirm_email_msg(email.clone(), "_matrix/client/unstable/add_threepid").await?;

    account
        .add_3pid(client_secret, sid, old_pswd.clone())
        .await?;

    let homeserver_name = option_env!("DEFAULT_HOMESERVER_NAME").unwrap_or("localhost");
    let homeserver_url = option_env!("DEFAULT_HOMESERVER_URL").unwrap_or("http://localhost:8118");

    let resp =
        request_password_change_token_via_email(homeserver_url.to_owned(), email.clone()).await?; // here m.login.email.identity is started

    info!("password change token via email - sid: {}", resp.sid());
    info!(
        "password change token via email - submit_url: {:?}",
        resp.submit_url(),
    );

    confirm_email_msg(email.clone(), "_synapse/client/password_reset").await?; // here m.login.email.identity is completed
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
        username.to_owned(),
        old_pswd,
        homeserver_name.to_owned(),
        homeserver_url.to_owned(),
        None,
    )
    .await;

    assert!(res.is_err(), "old password should be unavailable now");

    let base_dir = TempDir::new()?;
    let media_dir = TempDir::new()?;
    let res = login_new_client(
        base_dir.path().to_string_lossy().to_string(),
        media_dir.path().to_string_lossy().to_string(),
        username.to_owned(),
        new_pswd,
        homeserver_name.to_owned(),
        homeserver_url.to_owned(),
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
    let email = format!("{username}@example.org");
    let old_pswd = default_user_password(username);
    let account = client.account()?;
    let resp = account
        .request_3pid_management_token_via_email(email.clone())
        .await?;
    let client_secret = resp.client_secret();
    let sid = resp.sid();

    confirm_email_msg(email.clone(), "_matrix/client/unstable/add_threepid").await?;

    // confirm on the client side, too
    account
        .add_3pid(client_secret, sid, old_pswd.clone())
        .await?;

    client.logout().await?;

    let homeserver_name = option_env!("DEFAULT_HOMESERVER_NAME").unwrap_or("localhost");
    let homeserver_url = option_env!("DEFAULT_HOMESERVER_URL").unwrap_or("http://localhost:8118");

    let resp =
        request_password_change_token_via_email(homeserver_url.to_owned(), email.clone()).await?; // here m.login.email.identity is started

    info!("password change token via email - sid: {}", resp.sid());
    info!(
        "password change token via email - submit_url: {:?}",
        resp.submit_url(),
    );

    confirm_email_msg_with_post(email.clone(), "_synapse/client/password_reset").await?; // here m.login.email.identity is completed
    let new_pswd = format!("new_{}", &old_pswd);

    reset_password(
        homeserver_url.to_owned(),
        resp.sid(),
        resp.client_secret(),
        new_pswd.clone(),
    )
    .await?;

    let base_dir = TempDir::new()?;
    let media_dir = TempDir::new()?;
    let res = login_new_client(
        base_dir.path().to_string_lossy().to_string(),
        media_dir.path().to_string_lossy().to_string(),
        username.to_owned(),
        old_pswd,
        homeserver_name.to_owned(),
        homeserver_url.to_owned(),
        None,
    )
    .await;

    assert!(res.is_err(), "old password should be unavailable now");

    let base_dir = TempDir::new()?;
    let media_dir = TempDir::new()?;
    let res = login_new_client(
        base_dir.path().to_string_lossy().to_string(),
        media_dir.path().to_string_lossy().to_string(),
        username.to_owned(),
        new_pswd,
        homeserver_name.to_owned(),
        homeserver_url.to_owned(),
        None,
    )
    .await;

    assert!(res.is_ok(), "new password should be available now");

    Ok(())
}

async fn get_emails_of(email_addr: String) -> Result<MessageList> {
    let mailhog_url = option_env!("MAILHOG_URL")
        .unwrap_or("http://localhost:8025")
        .to_owned();
    let mailhog = MailHog::new(mailhog_url);
    let params = SearchParams {
        start: None,
        limit: None,
        kind: SearchKind::To,
        query: email_addr,
    };

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let mailhog_cl = mailhog.clone();
    let params_cl = params.clone();
    Retry::spawn(retry_strategy, move || {
        let mailhog = mailhog_cl.clone();
        let params = params_cl.clone();
        async move {
            let msg_list = mailhog.search(params).await?;
            if msg_list.count == 0 {
                bail!("email msg not found");
            }
            Ok(msg_list)
        }
    })
    .await
}

async fn confirm_email_msg(email_addr: String, dir: &str) -> Result<ReqResponse> {
    confirm_email_msg_inner(email_addr, dir, false).await
}

async fn confirm_email_msg_with_post(email_addr: String, dir: &str) -> Result<ReqResponse> {
    confirm_email_msg_inner(email_addr, dir, true).await
}

async fn confirm_email_msg_inner(
    email_addr: String,
    dir: &str,
    is_post: bool, // if false, it means GET method
) -> Result<ReqResponse> {
    let (token, client_secret, sid) = get_email_tokens(email_addr, dir).await?;

    let homeserver_url = option_env!("DEFAULT_HOMESERVER_URL").unwrap_or("http://localhost:8118");

    let client = ReqClient::new();
    let submit_url = format!("{homeserver_url}/{dir}/email/submit_token");
    let params = [
        ("token", token),
        ("client_secret", client_secret),
        ("sid", sid),
    ];
    let req_builder = if is_post {
        client.post(submit_url)
    } else {
        client.get(submit_url)
    };
    let req = req_builder.query(&params).build()?;

    let resp = client.execute(req).await?.error_for_status()?;
    Ok(resp)
}

async fn get_email_tokens(email_addr: String, dir: &str) -> Result<(String, String, String)> {
    let message_list = get_emails_of(email_addr).await?;
    let mut failures = vec![];
    for msg in message_list.items {
        info!("last msg content headers: {:?}", msg.content.headers);
        info!("last msg content body: {:?}", msg.content.body);
        info!("last msg created: {:?}", msg.created);
        info!("last msg from: {:?}", msg.from);
        info!("last msg id: {:?}", msg.id);

        let mut headers = vec![];
        for (key, vals) in msg.content.headers.iter() {
            for (pos, val) in vals.iter().enumerate() {
                if pos == 0 {
                    headers.push(format!("{key}: {val}"));
                } else {
                    headers.push(val.clone());
                }
            }
        }
        let content = format!("{}\r\n\r\n{}", headers.join("\r\n"), msg.content.body,);
        let mail_msg = MessageParser::default()
            .parse(&content)
            .context("mail content should be parsed")?;
        let plain_body = mail_msg
            .body_text(0)
            .context("plain text should be extracted")?
            .to_string();

        info!("plain body: {}", plain_body);

        let pattern = format!(
            r"(?m)^.*{dir}/email/submit_token\?token=(\w+)&client_secret=(\w+)&sid=(\w+)\n.*$",
        );
        let re = Regex::new(&pattern)?;
        if let Some(caps) = re.captures(&plain_body) {
            let token = caps
                .get(1)
                .map(|m| m.as_str())
                .expect("token should be available");
            let client_secret = caps
                .get(2)
                .map(|m| m.as_str())
                .expect("client secret should be available");
            let sid = caps
                .get(3)
                .map(|m| m.as_str())
                .expect("sid should be available");

            info!("token: {}", token);
            info!("client secret: {}", client_secret);
            info!("session id: {}", sid);

            return Ok((token.to_owned(), client_secret.to_owned(), sid.to_owned()));
        } else {
            failures.push(format!("should capture url ({pattern}): \n {plain_body}"))
        }
    }
    bail!("No email found matching: {}", failures.join("\n----\n"))
}
