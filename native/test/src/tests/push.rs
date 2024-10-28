use anyhow::Result;

use crate::utils::random_user;

#[tokio::test]
async fn acter_default_push_rules() -> Result<()> {
    let _ = env_logger::try_init();
    let user = random_user("acter_push_rules").await?;

    user.install_default_acter_push_rules().await?;
    let push_rules = user.push_rules().await?;

    assert!(
        push_rules
            .underride
            .iter()
            .any(|r| &r.rule_id == "global.acter.dev.news" && r.enabled),
        "Push Rule for updates wasn’t installed"
    );
    Ok(())
}
