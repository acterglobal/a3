#[derive(Debug, Eq, PartialEq)]
pub enum Capability {
    // someone can add reaction on this
    Reactable,
    // someone can add comment on this
    Commentable,
    // someone can add attachment on this
    Attachmentable,
    // users reads/views are being tracked
    ReadTracking,
    // someone can rsvp on this
    RSVPable,
    // someone can invite on this
    Inviteable,
    // another custom capability
    Custom(&'static str),
}
