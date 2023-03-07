use crate::utils::random_user_with_template;
use anyhow::Result;

const TMPL: &str = r#"
version = "0.1"
name = "Smoketest Template"

[inputs]
main = { type = "user", is-default = true, required = true, description = "The starting user" }

[objects]
main_space = { type = "space", is-default = true, name = "{{ main.display_name }}'s test space"}
start_list = { type = "task-list", name = "{{ main.display_name }}'s Acter onboarding list" }

[objects.task_1]
type = "task"
title = "Scroll through the news"
assignees = ["{{ main.user_id }}"]
"m.relates_to" = { event_id = "{{ start_list.id }}" } 
utc_due = "{{ now().as_rfc3339 }}"

[objects.acter-website-pin]
type = "pin"
title = "Acter Website"
url = "https://acter.global"

[objects.acter-source-pin]
type = "pin"
title = "Acter Source Code"
url = "https://github.com/acterglobal/a3"

        "#;

#[tokio::test]
async fn template_creates_space() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, _sync_state, _engine) = random_user_with_template("create-space-", TMPL).await?;
    assert_eq!(user.pins().await?.len(), 3);

    let groups = user.groups().await?;
    assert_eq!(groups.len(), 1);
    assert_eq!(groups[0].pins().await?.len(), 3);
    Ok(())
}
