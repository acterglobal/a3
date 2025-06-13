/// testing the ref details API
use anyhow::Result;

use acter::api::new_link_ref_details;

#[test]
fn test_ref_details_for_link_smoketest() -> Result<()> {
    let title = "Link Title";
    let uri = "mxc://acter.global/test";
    let ref_details = new_link_ref_details(title.to_owned(), uri.to_owned())?;
    assert_eq!(ref_details.type_str(), "link");
    assert_eq!(ref_details.title().as_deref(), Some(title));
    assert_eq!(ref_details.uri().as_deref(), Some(uri));

    // second one for good measure
    let title = "Smoketest";
    let uri = "https://matrix.org";
    let ref_details = new_link_ref_details(title.to_owned(), uri.to_owned())?;
    assert_eq!(ref_details.type_str(), "link");
    assert_eq!(ref_details.title().as_deref(), Some(title));
    assert_eq!(ref_details.uri().as_deref(), Some(uri));
    Ok(())
}
