use crate::utils::random_user_with_template;
use anyhow::Result;

const TMPL: &str = r#"
version = "0.1"
name = "Smoketest Template"

[inputs]
main = { type = "user", is-default = true, required = true, description = "The starting user" }

[objects]
main_space = { type = "space", is-default = true, name = "{{ main.display_name }}'s pins test space"}
[objects.acter-website-pin]
type = "pin"
title = "Acter Website"
url = "https://acter.global"

[objects.acter-source-pin]
type = "pin"
title = "Acter Source Code"
url = "https://github.com/acterglobal/a3"

[objects.example-data-pin]
type = "pin"
title = "Acter example pin"
content = { body = "example pin data" }
"#;

#[tokio::test]
async fn pins_smoketest() -> Result<()> {
    let _ = env_logger::try_init();
    let (_user, _sync_state, _engine) = random_user_with_template("pins-smoke-", TMPL).await?;
    // user.get_pins();
    Ok(())
}
