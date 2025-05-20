/// testing the ref details API
use anyhow::Result;

use acter::api::new_link_ref_details;

#[test]
fn test_ref_details_for_link_smoketest() -> Result<()> {
    let ref_details = new_link_ref_details(
        "Link Title".to_owned(),
        "mxc://acter.global/test".to_owned(),
    )?;
    assert_eq!(ref_details.type_str(), "link");
    assert_eq!(ref_details.title().as_deref(), Some("Link Title"));
    assert_eq!(
        ref_details.uri().as_deref(),
        Some("mxc://acter.global/test")
    );

    // second one for good measure
    let ref_details =
        new_link_ref_details("Smoketest".to_owned(), "https://matrix.org".to_owned())?;
    assert_eq!(ref_details.type_str(), "link");
    assert_eq!(ref_details.title().as_deref(), Some("Smoketest"));
    assert_eq!(ref_details.uri().as_deref(), Some("https://matrix.org"));
    Ok(())
}
