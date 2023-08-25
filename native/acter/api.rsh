/// Initialize logging
fn init_logging(log_dir: string, filter: string) -> Result<()>;

/// Rotate the logging file
fn rotate_log_file() -> Result<string>;

/// Allow flutter to call logging on rust side
fn write_log(text: string, level: string) -> Result<()>;

/// Create a new client for homeserver at url with storage at data_path
fn login_new_client(basepath: string, username: string, password: string, default_homeserver_name: string, default_homeserver_url: string, device_name: Option<string>) -> Future<Result<Client>>;

/// Create a new client from the restore token
fn login_with_token(basepath: string, restore_token: string) -> Future<Result<Client>>;

/// Create an anonymous client connecting to the homeserver
fn guest_client(basepath: string, default_homeserver_name: string, default_homeserver_url: string, device_name: Option<string>) -> Future<Result<Client>>;

/// Create a new client from the registration token
fn register_with_token(basepath: string, username: string, password: string, registration_token: string, default_homeserver_name: string, default_homeserver_url: string, device_name: string) -> Future<Result<Client>>;

/// Representing a time frame
object EfkDuration {}

fn duration_from_secs(secs: u64) -> EfkDuration;

/// Representing a color
object EfkColor {
    /// as rgba in u8
    fn rgba_u8() -> (u8, u8, u8, u8);
}

object UtcDateTime {
    fn timestamp() -> i64;
    fn to_rfc2822() -> string;
    fn to_rfc3339() -> string;
    fn timestamp_millis()-> i64;
}

object RefDetails {
    /// the target id
    fn target_id_str() -> Option<string>;
    /// if that is in a different room, specified here
    fn room_id_str() -> Option<string>;
    /// gives either `link`, `task`, `task-list` or `calendar_client`
    fn type_str() -> string;
    /// what type of embed action is requested_inputs
    fn embed_action_str() -> string;
    /// if this is a `task` type, what `task-list-id` does it belong to
    fn task_list_id_str() -> Option<string>;
    /// if ref is `link`, its display title
    fn title() -> Option<string>;
    /// if ref is `link`, its uri
    fn uri() -> Option<string>;
}

/// An acter internal link to a different object
object ObjRef {
    /// where to position the element (if given)
    fn position_str() -> Option<string>;
    /// further details of the reference
    fn reference() -> RefDetails;
}

/// A foreground and background color setting
object Colorize {
    /// Foreground or text color
    fn color() -> Option<EfkColor>;
    /// Background color
    fn background() -> Option<EfkColor>;
}

/// A single Slide of a NewsEntry
object NewsSlide {
    /// the content of this slide
    fn type_str() -> string;

    /// whether this text-slide has a formatted html body
    fn has_formatted_text() -> bool;
    /// the textual content of this slide
    fn text() -> string;
    /// the references linked in this slide
    fn references() -> Vec<ObjRef>;

    /// if this is an image, hand over the description
    fn image_desc() -> Option<ImageDesc>;
    /// if this is an image, hand over the data
    fn image_binary() -> Future<Result<buffer<u8>>>;

    /// if this is an audio, hand over the description
    fn audio_desc() -> Option<AudioDesc>;
    /// if this is an audio, hand over the data
    fn audio_binary() -> Future<Result<buffer<u8>>>;

    /// if this is a video, hand over the description
    fn video_desc() -> Option<VideoDesc>;
    /// if this is a video, hand over the data
    fn video_binary() -> Future<Result<buffer<u8>>>;

    /// if this is a file, hand over the description
    fn file_desc() -> Option<FileDesc>;
    /// if this is a file, hand over the data
    fn file_binary() -> Future<Result<buffer<u8>>>;
}

/// A news entry
object NewsEntry {
    fn slides_count() -> u8;
    /// The slides belonging to this news item
    fn get_slide(pos: u8) -> Option<NewsSlide>;
    /// The color setting
    fn colors() -> Option<Colorize>;

    /// how many comments on this news entry
    fn comments_count() -> u32;
    /// how many likes on this news entry
    fn likes_count() -> u32;

    /// get room id
    fn room_id() -> RoomId;
}

object NewsEntryDraft {
    /// create news slide for text msg
    fn add_text_slide(body: string);

    /// create news slide for image msg
    fn add_image_slide(body: string, url: string, mimetype: string, size: Option<u32>, width: Option<u32>, height: Option<u32>, blurhash: Option<string>) -> Future<Result<bool>>;

    /// create news slide for audio msg
    fn add_audio_slide(body: string, url: string, secs: Option<u32>, mimetype: Option<string>, size: Option<u32>);

    /// create news slide for video msg
    fn add_video_slide(body: string, url: string, secs: Option<u32>, height: Option<u32>, width: Option<u32>, mimetype: Option<string>, size: Option<u32>, blurhash: Option<string>);

    /// create news slide for file msg
    fn add_file_slide(body: string, url: string, mimetype: Option<string>, size: Option<u32>);

    /// clear slides
    fn unset_slides();

    /// set the color for this news entry
    fn colors(colors: Colorize);
    fn unset_colors();

    /// create this news entry
    fn send() -> Future<Result<EventId>>;
}

object NewsEntryUpdateBuilder {
    /// set the slides for this news entry
    fn slides(slides: Vec<NewsSlide>);
    fn unset_slides();
    fn unset_slides_update();

    /// set the color for this news entry
    fn colors(colors: Colorize);
    fn unset_colors();
    fn unset_colors_update();

    /// update this news entry
    fn send() -> Future<Result<EventId>>;
}

object Tag {
    /// the title of the tag
    fn title() -> string;
    /// dash-cased-ascii-version for usage in hashtags (no `#` at the front)
    fn hash_tag() -> string;
    /// if given, the specific color for this tag
    fn color() -> Option<EfkColor>;
}

/// Draft a Pin
object PinDraft {
    /// set the title for this pin
    fn title(title: string);

    /// set the content for this pin
    fn content_text(text: string);
    /// set the content of the pin through markdown
    fn content_markdown(text: string);
    fn unset_content();

    /// set the url for this pin
    fn url(text: string);
    fn unset_url();

    /// fire this pin over - the event_id is the confirmation from the server.
    fn send() -> Future<Result<EventId>>;
}

/// A pin object
object ActerPin {
    /// get the title of the pin
    fn title() -> string;
    /// get the content_text of the pin
    fn content_text() -> Option<string>;
    /// get the formatted content of the pin
    fn content_formatted() -> Option<string>;
    /// Whether the inner text is coming as formatted
    fn has_formatted_text() -> bool;
    /// whether this pin is a link
    fn is_link() -> bool;
    /// get the link content
    fn url() -> Option<string>;
    /// get the link color settings
    fn color() -> Option<EfkColor>;
    /// The room this Pin belongs to
    //fn team() -> Room;

    /// the unique event ID
    //fn event_id() -> EventId;
    fn event_id_str() -> string;
    /// the room/space this item belongs to
    fn room_id_str() -> string;

    /// make a builder for updating the pin
    fn update_builder() -> Result<PinUpdateBuilder>;

    /// get informed about changes to this pin
    fn subscribe_stream() -> Stream<bool>;

    /// replace the current pin with one with the latest state
    fn refresh() -> Future<Result<ActerPin>>;

    /// get the comments manager for this pin
    fn comments() -> Future<Result<CommentsManager>>;

    /// get the attachments manager for this pin
    fn attachments() -> Future<Result<AttachmentsManager>>;
}

object PinUpdateBuilder {
    /// set the title for this pin
    fn title(title: string);
    fn unset_title_update();

    /// set the content for this pin
    fn content_text(text: string);
    fn unset_content();
    fn unset_content_update();

    /// set the url for this pin
    fn url(text: string);
    fn unset_url();
    fn unset_url_update();

    /// fire this update over - the event_id is the confirmation from the server.
    fn send() -> Future<Result<EventId>>;
}

// enum LocationType {
//    Physical,
//    Virtual
// }

// object Location {
//    /// "physical" or "virtual"
//    fn location_type() -> string;
//    fn name() -> Option<string>;
//    fn description() -> Option<TextMessageContent>;
//    fn coordinates() -> Option<string>;
//    fn uri() -> Option<string>;
//}

object TextMessageContent {
    fn body() -> string;
    fn formatted() -> Option<string>;
}

object CalendarEvent {
    /// the title of the event
    fn title() -> string;
    /// description text
    fn description() -> Option<TextMessageContent>;
    /// When the event starts
    fn utc_start() -> UtcDateTime;
    /// When the event ends
    fn utc_end() -> UtcDateTime;
    /// whether to show the time or just the dates
    fn show_without_time() -> bool;
    /// locations
    // fn locations() -> Vec<Location>;
    /// event id
    fn event_id() -> EventId;
    /// update builder
    fn update_builder() -> Result<CalendarEventUpdateBuilder>;
    /// get RSVP manager
    fn rsvp_manager() -> Future<Result<RsvpManager>>;
}

object CalendarEventUpdateBuilder {
    /// set title of the event>
    fn title(title: string);
    /// set description text
    fn description_text(body: string);
    /// set utc start in rfc3339 string
    fn utc_start_from_rfc3339(utc_start: string);
    /// set utc start in rfc2822 string
    fn utc_start_from_rfc2822(utc_start: string);
    /// set utc start in custom format
    fn utc_start_from_format(utc_start: string, format: string);
    /// set utc end in rfc3339 string
    fn utc_end_from_rfc3339(utc_end: string);
    /// set utc end in rfc2822 string
    fn utc_end_from_rfc2822(utc_end: string);
    /// set utc end in custom format
    fn utc_end_from_format(utc_end: string, format: string);
    /// send builder update
    fn send() -> Future<Result<EventId>>;
}

object CalendarEventDraft {
    /// set the title for this calendar event
    fn title(title: string);

    /// set the description for this calendar event
    fn description_text(text: string);
    fn unset_description();

    /// set the utc_start for this calendar event in rfc3339 format
    fn utc_start_from_rfc3339(utc_start: string) -> Result<()>;
    /// set the utc_start for this calendar event in rfc2822 format
    fn utc_start_from_rfc2822(utc_start: string)-> Result<()>;
    /// set the utc_start for this calendar event in custom format
    fn utc_start_from_format(utc_start: string, format: string)-> Result<()>;

    /// set the utc_end for this calendar event in rfc3339 format
    fn utc_end_from_rfc3339(utc_end: string) -> Result<()>;
    /// set the utc_end for this calendar event in rfc2822 format
    fn utc_end_from_rfc2822(utc_end: string)-> Result<()>;
    /// set the utc_end for this calendar event in custom format
    fn utc_end_from_format(utc_end: string, format: string)-> Result<()>;

    /// create this calendar event
    fn send() -> Future<Result<EventId>>;
}

object RsvpManager {
    /// whether manager has rsvp entries
    fn has_rsvp_entries() -> bool;

    /// get total rsvp count
    fn total_rsvp_count() -> u32;

    /// get rsvp entries
    fn rsvp_entries() -> Future<Result<Vec<Rsvp>>>;

    /// get Yes/Maybe/No/None for the user's own status
    fn my_status() -> Future<Result<OptionString>>;

    /// get the count of Yes/Maybe/No
    fn count_at_status(status: string) -> Future<Result<u32>>;

    /// get the user-ids that have responded said way for each status
    fn users_at_status(status: string) -> Future<Result<Vec<UserId>>>;

    /// create rsvp draft
    fn rsvp_draft() -> Result<RsvpDraft>;

    /// get informed about changes to this manager
    fn subscribe_stream() -> Stream<()>;
}

object RsvpDraft {
    /// set status of this RSVP
    fn status(status: string) -> RsvpDraft;

    /// create this RSVP
    fn send() -> Future<Result<EventId>>;
}

object Rsvp {
    /// get sender of this rsvp
    fn sender() -> UserId;

    /// get timestamp of this rsvp
    fn origin_server_ts() -> u64;

    /// get status of this rsvp
    fn status() -> string;
}

object MediaSource {
    fn url() -> string;
}

object ThumbnailInfo {
    /// thumbnail mimetype
    fn mimetype() -> Option<string>;
    /// thumbnail size
    fn size() -> Option<u32>;
    /// thumbnail width
    fn width() -> Option<u32>;
    /// thumbnail height
    fn height() -> Option<u32>;
}

object DeviceId {
    fn to_string() -> string;
}

object EventId {
    fn to_string() -> string;
}

object MxcUri {
    fn to_string() -> string;
}

object RoomId {
    fn to_string() -> string;
}

object UserId {
    fn to_string() -> string;
}

/// A room Message metadata and content
object RoomEventItem {
    /// Unique ID of this event
    fn event_id() -> string;

    /// The User, who sent that event
    fn sender() -> string;

    /// the server receiving timestamp in milliseconds
    fn origin_server_ts() -> u64;

    /// one of Message/Redaction/UnableToDecrypt/FailedToParseMessageLike/FailedToParseState
    fn event_type() -> string;

    /// the type of massage, like text, image, audio, video, file etc
    fn sub_type() -> Option<string>;

    /// contains text fallback and formatted text
    fn text_desc() -> Option<TextDesc>;

    /// contains source data, name, mimetype, size, width and height
    fn image_desc() -> Option<ImageDesc>;

    /// contains source data, name, mimetype, duration and size
    fn audio_desc() -> Option<AudioDesc>;

    /// contains source data, name, mimetype, duration, size, width, height and blurhash
    fn video_desc() -> Option<VideoDesc>;

    /// contains source data, name, mimetype and size
    fn file_desc() -> Option<FileDesc>;

    /// original event id, if this msg is reply to another msg
    fn in_reply_to() -> Option<string>;

    /// the emote key list that users reacted about this message
    fn reaction_keys() -> Vec<string>;

    /// the details that users reacted using this emote key in this message
    fn reaction_items(key: string) -> Option<Vec<ReactionRecord>>;

    /// Whether this message is editable
    fn is_editable() -> bool;
}

object RoomVirtualItem {
    /// DayDivider or ReadMarker
    fn event_type() -> string;

    /// contains description text
    fn desc() -> Option<string>;
}

/// A room Message metadata and content
object RoomMessage {
    /// one of event/virtual
    fn item_type() -> string;

    /// room ID of this event
    fn room_id() -> RoomId;

    /// valid only if item_type is "event"
    fn event_item() -> Option<RoomEventItem>;

    /// valid only if item_type is "virtual"
    fn virtual_item() -> Option<RoomVirtualItem>;
}

object TextDesc {
    /// fallback text
    fn body() -> string;

    /// formatted text
    fn formatted_body() -> Option<string>;
}

object ImageDesc {
    /// file name
    fn name() -> string;

    /// image source
    fn source() -> MediaSource;

    /// MIME
    fn mimetype() -> Option<string>;

    /// file size in bytes
    fn size() -> Option<u32>;

    /// image width
    fn width() -> Option<u32>;

    /// image height
    fn height() -> Option<u32>;

    /// thumbnail info
    fn thumbnail_info() -> Option<ThumbnailInfo>;

    /// thumbnail source
    fn thumbnail_source() -> Option<MediaSource>;
}

object AudioDesc {
    /// file name
    fn name() -> string;

    /// audio source
    fn source() -> MediaSource;

    /// MIME
    fn mimetype() -> Option<string>;

    /// file size in bytes
    fn size() -> Option<u32>;

    /// duration in seconds
    fn duration() -> Option<u32>;
}

object VideoDesc {
    /// file name
    fn name() -> string;

    /// video source
    fn source() -> MediaSource;

    /// MIME
    fn mimetype() -> Option<string>;

    /// file size in bytes
    fn size() -> Option<u32>;

    /// image width
    fn width() -> Option<u32>;

    /// image height
    fn height() -> Option<u32>;

    /// blurhash
    fn blurhash() -> Option<string>;

    /// duration in seconds
    fn duration() -> Option<u32>;

    /// thumbnail info
    fn thumbnail_info() -> Option<ThumbnailInfo>;

    /// thumbnail source
    fn thumbnail_source() -> Option<MediaSource>;
}

object FileDesc {
    /// file name
    fn name() -> string;

    /// file source
    fn source() -> MediaSource;

    /// MIME
    fn mimetype() -> Option<string>;

    /// file size in bytes
    fn size() -> Option<u32>;

    /// thumbnail info
    fn thumbnail_info() -> Option<ThumbnailInfo>;

    /// thumbnail source
    fn thumbnail_source() -> Option<MediaSource>;
}

object ReactionRecord {
    /// who sent reaction
    fn sender_id() -> UserId;

    /// when reaction was sent
    fn timestamp() -> u64;
}

object TimelineDiff {
    /// Append/Insert/Set/Remove/PushBack/PushFront/PopBack/PopFront/Clear/Reset
    fn action() -> string;

    /// for Append/Reset
    fn values() -> Option<Vec<RoomMessage>>;

    /// for Insert/Set/Remove
    fn index() -> Option<usize>;

    /// for Insert/Set/PushBack/PushFront
    fn value() -> Option<RoomMessage>;
}

/// Timeline with Room Events
object TimelineStream {
    /// Fires whenever new diff found
    fn diff_rx() -> Stream<TimelineDiff>;

    /// Fires whenever new event arrived
    fn next() -> Future<Result<RoomMessage>>;

    /// Get the next count messages backwards, and return whether it has more items
    fn paginate_backwards(count: u16) -> Future<Result<bool>>;

    /// modify the room message
    fn edit(new_msg: string, original_event_id: string, txn_id: Option<string>) -> Future<Result<bool>>;
}

object Convo {
    /// get the room profile that contains avatar and display name
    fn get_profile() -> RoomProfile;

    /// Change the avatar of the room
    fn upload_avatar(uri: string) -> Future<Result<MxcUri>>;

    /// Remove the avatar of the room
    fn remove_avatar() -> Future<Result<EventId>>;

    /// what is the description / topic
    fn topic() -> Option<string>;

    /// set description / topic of the room
    fn set_topic(topic: string) -> Future<Result<EventId>>;

    /// the members currently in the room
    fn active_members() -> Future<Result<Vec<Member>>>;

    /// the members invited to this room
    fn invited_members() -> Future<Result<Vec<Member>>>;

    /// get the room member by user id
    fn get_member(user_id: string) -> Future<Result<Member>>;

    /// Get the timeline for the room
    fn timeline_stream() -> Future<Result<TimelineStream>>;

    /// The last message sent to the room
    fn latest_message() -> Option<RoomMessage>;

    /// the Membership of myself
    fn get_my_membership() -> Future<Result<Member>>;

    /// the room id
    fn get_room_id() -> RoomId;

    /// the room id as str
    fn get_room_id_str() -> string;

    /// Activate typing notice for this room
    /// The typing notice remains active for 4s. It can be deactivate at any
    /// point by setting typing to false. If this method is called while the
    /// typing notice is active nothing will happen. This method can be called
    /// on every key stroke, since it will do nothing while typing is active.
    fn typing_notice(typing: bool) -> Future<Result<bool>>;

    /// Send a request to notify this room that the user has read specific event.
    fn read_receipt(event_id: string) -> Future<Result<bool>>;

    /// Send a simple plain text message to the room
    /// returns the event_id as given by the server of the event soon after
    /// received over timeline().next()
    fn send_plain_message(text_message: string) -> Future<Result<EventId>>;

    /// Send a text message in MarkDown format to the room
    fn send_formatted_message(markdown_message: string) -> Future<Result<EventId>>;

    /// Send reaction about existing event
    fn send_reaction(event_id: string, key: string) -> Future<Result<EventId>>;

    /// send the image message to this room
    fn send_image_message(uri: string, name: string, mimetype: string, size: Option<u32>, width: Option<u32>, height: Option<u32>, blurhash: Option<string>) -> Future<Result<EventId>>;

    /// decrypted image file data
    /// The reason that this function belongs to room object is because ChatScreen keeps it as member variable
    /// If this function belongs to message object, we may have to load too many message objects in ChatScreen
    fn image_binary(event_id: string) -> Future<Result<buffer<u8>>>;

    /// send the audio message to this room
    fn send_audio_message(uri: string, name: string, mimetype: string, secs: Option<u32>, size: Option<u32>) -> Future<Result<EventId>>;

    /// decrypted audio buffer data
    /// The reason that this function belongs to room object is because ChatScreen keeps it as member variable
    /// If this function belongs to message object, we may have to load too many message objects in ChatScreen
    fn audio_binary(event_id: string) -> Future<Result<buffer<u8>>>;

    /// send the video message to this room
    fn send_video_message(uri: string, name: string, mimetype: string, secs: Option<u32>, height: Option<u32>, width: Option<u32>, size: Option<u32>, blurhash: Option<string>) -> Future<Result<EventId>>;

    /// decrypted video buffer data
    /// The reason that this function belongs to room object is because ChatScreen keeps it as member variable
    /// If this function belongs to message object, we may have to load too many message objects in ChatScreen
    fn video_binary(event_id: string) -> Future<Result<buffer<u8>>>;

    /// send the file message to this room
    fn send_file_message(uri: string, name: string, mimetype: string, size: u32) -> Future<Result<EventId>>;

    /// decrypted file buffer data
    /// The reason that this function belongs to room object is because ChatScreen keeps it as member variable
    /// If this function belongs to message object, we may have to load too many message objects in ChatScreen
    fn file_binary(event_id: string) -> Future<Result<buffer<u8>>>;

    /// get the user status on this room
    fn room_type() -> string;

    /// invite the new user to this room
    fn invite_user(user_id: string) -> Future<Result<bool>>;

    /// join this room
    fn join() -> Future<Result<bool>>;

    /// leave this room
    fn leave() -> Future<Result<bool>>;

    /// get the users that were invited to this room
    fn get_invitees() -> Future<Result<Vec<Member>>>;

    /// download media (image/audio/video/file) to specified path
    fn download_media(event_id: string, dir_path: string) -> Future<Result<string>>;

    /// get the path that media (image/audio/video/file) was saved
    fn media_path(event_id: string) -> Future<Result<string>>;

    /// initially called to get receipt status of room members
    fn user_receipts() -> Future<Result<Vec<ReceiptRecord>>>;

    /// whether this room is encrypted one
    fn is_encrypted() -> Future<Result<bool>>;

    /// get original of reply msg
    fn get_message(event_id: string) -> Future<Result<RoomMessage>>;

    /// send reply as text
    fn send_text_reply(msg: string, event_id: string, txn_id: Option<string>) -> Future<Result<EventId>>;

    /// send reply as image
    fn send_image_reply(uri: string, name: string, mimetype: string, size: Option<u32>, width: Option<u32>, height: Option<u32>, event_id: string, txn_id: Option<string>) -> Future<Result<EventId>>;

    /// send reply as audio
    fn send_audio_reply(uri: string, name: string, mimetype: string, secs: Option<u32>, size: Option<u32>, event_id: string, txn_id: Option<string>) -> Future<Result<EventId>>;

    /// send reply as video
    fn send_video_reply(uri: string, name: string, mimetype: string, secs: Option<u32>, width: Option<u32>, height: Option<u32>, size: Option<u32>, blurhash: Option<string>, event_id: string, txn_id: Option<string>) -> Future<Result<EventId>>;

    /// send reply as file
    fn send_file_reply(uri: string, name: string, mimetype: string, size: Option<u32>, event_id: string, txn_id: Option<string>) -> Future<Result<EventId>>;

    /// redact any message (including text/image/file and reaction)
    fn redact_message(event_id: string, reason: Option<string>, txn_id: Option<string>) -> Future<Result<EventId>>;

    /// update the power levels of specified member
    fn update_power_level(user_id: string, level: i32) -> Future<Result<EventId>>;

    fn is_joined() -> bool;
}

object CommentDraft {
    /// set the content of the draft to body
    fn content_text(body: string);

    /// set the content to a formatted body of html_body, where body is the tag-stripped version
    fn content_formatted(body: string, html_body: string);

    /// fire this comment over - the event_id is the confirmation from the server.
    fn send() -> Future<Result<EventId>>;
}

object Comment {
    /// Who send this comment
    fn sender() -> UserId;
    /// When was this comment acknowledged by the server
    fn origin_server_ts() -> u64;
    /// what is the comment's content in raw text
    fn content_text() -> string;
    /// what is the comment's content in html text
    fn content_formatted() -> Option<string>;
    /// create a draft builder to reply to this comment
    fn reply_builder() -> CommentDraft;
}

/// Reference to the comments section of a particular item
object CommentsManager {
    /// Get the list of comments (in arrival order)
    fn comments() -> Future<Result<Vec<Comment>>>;

    /// Does this item have any comments?
    fn has_comments() -> bool;

    /// How many comments does this item have
    fn comments_count() -> u32;

    /// draft a new comment for this item
    fn comment_draft() -> CommentDraft;
}

object AttachmentDraft {
    /// fire this attachment over - the event_id is the confirmation from the server.
    fn send() -> Future<Result<EventId>>;
}

object Attachment {
    /// Who send this attachment
    fn sender() -> UserId;
    /// When was this attachment acknowledged by the server
    fn origin_server_ts() -> u64;

    /// if this is an image, hand over the description
    fn image_desc() -> Option<ImageDesc>;
    /// if this is an image, hand over the data
    fn image_binary() -> Future<Result<buffer<u8>>>;

    /// if this is an audio, hand over the description
    fn audio_desc() -> Option<AudioDesc>;
    /// if this is an audio, hand over the data
    fn audio_binary() -> Future<Result<buffer<u8>>>;

    /// if this is a video, hand over the description
    fn video_desc() -> Option<VideoDesc>;
    /// if this is a video, hand over the data
    fn video_binary() -> Future<Result<buffer<u8>>>;

    /// if this is a file, hand over the description
    fn file_desc() -> Option<FileDesc>;
    /// if this is a file, hand over the data
    fn file_binary() -> Future<Result<buffer<u8>>>;
}

/// Reference to the attachments section of a particular item
object AttachmentsManager {
    /// Get the list of attachments (in arrival order)
    fn attachments() -> Future<Result<Vec<Attachment>>>;

    /// Does this item have any attachments?
    fn has_attachments() -> bool;

    /// How many attachments does this item have
    fn attachments_count() -> u32;

    /// draft a new attachment for this item
    fn attachment_draft() -> AttachmentDraft;

    /// create news slide for image msg
    fn image_attachment_draft(body: string, url: string, mimetype: Option<string>, size: Option<u32>, width: Option<u32>, height: Option<u32>, blurhash: Option<string>) -> AttachmentDraft;

    /// create news slide for audio msg
    fn audio_attachment_draft(body: string, url: string, secs: Option<u32>, mimetype: Option<string>, size: Option<u32>) -> AttachmentDraft;

    /// create news slide for video msg
    fn video_attachment_draft(body: string, url: string, secs: Option<u32>, height: Option<u32>, width: Option<u32>, mimetype: Option<string>, size: Option<u32>, blurhash: Option<string>) -> AttachmentDraft;

    /// create news slide for file msg
    fn file_attachment_draft(body: string, url: string, mimetype: Option<string>, size: Option<u32>) -> AttachmentDraft;
}

object Task {
    /// the name of this task
    fn title() -> string;

    /// the description of this task
    fn description_text() -> Option<string>;

    /// the users assigned
    fn assignees() -> Vec<UserId>;

    /// other users to inform about updates
    fn subscribers() -> Vec<UserId>;

    /// order in the list
    fn sort_order() -> u32;

    /// does this list have a special role?
    /// Highest = 1,
    /// SecondHighest = 2,
    /// Three = 3,
    /// Four = 4,
    /// Five = 5,
    /// Six = 6,
    /// Seven = 7,
    ///  --- No value
    /// SecondLowest = 8,
    /// Lowest = 9,
    fn priority() -> Option<u8>;

    /// When this is due
    fn utc_due() -> Option<UtcDateTime>;

    /// When this was started
    fn utc_start() -> Option<UtcDateTime>;

    /// Has this been colored in?
    fn color() -> Option<EfkColor>;

    /// is this task already done?
    fn is_done() -> bool;

    /// if it has been started, haw far is it in percent 0->100
    /// None if not yet started
    fn progress_percent() -> Option<u8>;

    /// tags on this task
    fn keywords() -> Vec<string>;

    /// categories this task is in
    fn categories() -> Vec<string>;

    /// make a builder for updating the task
    fn update_builder() -> Result<TaskUpdateBuilder>;

    /// get informed about changes to this task
    fn subscribe_stream() -> Stream<bool>;

    /// replace the current task with one with the latest state
    fn refresh() -> Future<Result<Task>>;

    /// get the comments manager for this task
    fn comments() -> Future<Result<CommentsManager>>;
}

object TaskUpdateBuilder {
    /// set the title for this task
    fn title(title: string);
    fn unset_title_update();

    /// set the description for this task list
    fn description_text(text: string);
    fn unset_description();
    fn unset_description_update();

    /// set the sort order for this task list
    fn sort_order(sort_order: u32);
    fn unset_sort_order_update();

    /// set the color for this task list
    fn color(color: EfkColor);
    fn unset_color();
    fn unset_color_update();

    /// set the utc_due for this task list in rfc3339 format
    fn utc_due_from_rfc3339(utc_due: string) -> Result<()>;
    /// set the utc_due for this task list in rfc2822 format
    fn utc_due_from_rfc2822(utc_due: string)-> Result<()>;
    /// set the utc_due for this task list in custom format
    fn utc_due_from_format(utc_due: string, format: string)-> Result<()>;
    fn unset_utc_due();
    fn unset_utc_due_update();

    /// set the utc_start for this task list in rfc3339 format
    fn utc_start_from_rfc3339(utc_start: string) -> Result<()>;
    /// set the utc_start for this task list in rfc2822 format
    fn utc_start_from_rfc2822(utc_start: string)-> Result<()>;
    /// set the utc_start for this task list in custom format
    fn utc_start_from_format(utc_start: string, format: string)-> Result<()>;
    fn unset_utc_start();
    fn unset_utc_start_update();

    /// set the sort order for this task list
    fn progress_percent(progress_percent: u8);
    fn unset_progress_percent();
    fn unset_progress_percent_update();

    /// set the keywords for this task list
    fn keywords(keywords: Vec<string>);
    fn unset_keywords();
    fn unset_keywords_update();

    /// set the categories for this task list
    fn categories(categories: Vec<string>);
    fn unset_categories();
    fn unset_categories_update();

    /// set the assignees for this task list
    fn assignees(assignees: Vec<UserId>);
    fn unset_assignees();
    fn unset_assignees_update();

    /// set the subscribers for this task list
    fn subscribers(subscribers: Vec<UserId>);
    fn unset_subscribers();
    fn unset_subscribers_update();

    /// send this task list draft
    /// mark it done
    fn mark_done();

    /// mark as not done
    fn mark_undone();

    /// update this task
    fn send() -> Future<Result<EventId>>;
}

object TaskDraft {
    /// set the title for this task
    fn title(title: string);

    /// set the description for this task
    fn description_text(text: string);
    fn unset_description();

    /// set the sort order for this task
    fn sort_order(sort_order: u32);

    /// set the color for this task
    fn color(color: EfkColor);
    fn unset_color();

    /// set the utc_due for this task in rfc3339 format
    fn utc_due_from_rfc3339(utc_due: string) -> Result<()>;
    /// set the utc_due for this task in rfc2822 format
    fn utc_due_from_rfc2822(utc_due: string)-> Result<()>;
    /// set the utc_due for this task in custom format
    fn utc_due_from_format(utc_due: string, format: string)-> Result<()>;
    fn unset_utc_due();

    /// set the utc_start for this task in rfc3339 format
    fn utc_start_from_rfc3339(utc_start: string) -> Result<()>;
    /// set the utc_start for this task in rfc2822 format
    fn utc_start_from_rfc2822(utc_start: string)-> Result<()>;
    /// set the utc_start for this task in custom format
    fn utc_start_from_format(utc_start: string, format: string)-> Result<()>;
    fn unset_utc_start();

    /// set the sort order for this task
    fn progress_percent(progress_percent: u8);
    fn unset_progress_percent();

    /// set the keywords for this task
    fn keywords(keywords: Vec<string>);
    fn unset_keywords();

    /// set the categories for this task
    fn categories(categories: Vec<string>);
    fn unset_categories();

    /// set the assignees for this task
    fn assignees(assignees: Vec<UserId>);
    fn unset_assignees();

    /// set the subscribers for this task
    fn subscribers(subscribers: Vec<UserId>);
    fn unset_subscribers();

    /// create this task
    fn send() -> Future<Result<EventId>>;
}

object TaskList {
    /// the name of this task list
    fn name() -> string;

    /// the description of this task list
    fn description_text() -> Option<string>;

    /// who wants to be informed on updates about this?
    fn subscribers() -> Vec<UserId>;

    /// does this list have a special role?
    fn role() -> Option<string>;

    /// order in the list
    fn sort_order() -> u32;

    /// Has this been colored in?
    fn color() -> Option<EfkColor>;

    /// Does this have any special time zone
    fn time_zone() -> Option<string>;

    /// tags on this task
    fn keywords() -> Vec<string>;

    /// categories this task is in
    fn categories() -> Vec<string>;

    /// The tasks belonging to this tasklist
    fn tasks() -> Future<Result<Vec<Task>>>;

    /// make a builder for creating the task draft
    fn task_builder() -> Result<TaskDraft>;

    /// make a builder for updating the task list
    fn update_builder() -> Result<TaskListUpdateBuilder>;

    /// get informed about changes to this task
    fn subscribe_stream() -> Stream<bool>;

    /// replace the current task with one with the latest state
    fn refresh() -> Future<Result<TaskList>>;

    /// the space this TaskList belongs to
    fn space() -> Space;
}

object TaskListDraft {
    /// set the name for this task list
    fn name(name: string);

    /// set the description for this task list
    fn description_text(text: string);
    fn unset_description();

    /// set the sort order for this task list
    fn sort_order(sort_order: u32);

    /// set the color for this task list
    fn color(color: EfkColor);
    fn unset_color();

    /// set the keywords for this task list
    fn keywords(keywords: Vec<string>);
    fn unset_keywords();

    /// set the categories for this task list
    fn categories(categories: Vec<string>);
    fn unset_categories();

    /// set the subscribers for this task list
    fn subscribers(subscribers: Vec<UserId>);
    fn unset_subscribers();

    /// create this task list
    fn send() -> Future<Result<EventId>>;
}

object TaskListUpdateBuilder {
    /// set the name for this task list
    fn name(name: string);

    /// set the description for this task list
    fn description_text(text: string);
    fn unset_description();
    fn unset_description_update();

    /// set the sort order for this task list
    fn sort_order(sort_order: u32);

    /// set the color for this task list
    fn color(color: EfkColor);
    fn unset_color();
    fn unset_color_update();

    /// set the keywords for this task list
    fn keywords(keywords: Vec<string>);
    fn unset_keywords();
    fn unset_keywords_update();

    /// set the categories for this task list
    fn categories(categories: Vec<string>);
    fn unset_categories();
    fn unset_categories_update();

    /// set the subscribers for this task list
    fn subscribers(subscribers: Vec<UserId>);
    fn unset_subscribers();
    fn unset_subscribers_update();

    /// update this task
    fn send() -> Future<Result<EventId>>;
}


enum RelationTargetType {
    Unknown,
    ChatRoom,
    Space,
    ActerSpace
}

/// remote info
object SpaceHierarchyRoomInfo {
    fn name() -> Option<string>;
    //fn room_id() -> OwnedRoomId;
    fn room_id_str() -> string;
    fn topic() -> Option<string>;
    fn num_joined_members() -> u64;
    fn world_readable() -> bool;
    fn guest_can_join() -> bool;
    fn is_space() -> bool;
    fn avatar_url_str() -> Option<string>;
    fn join_rule_str() -> string;
    /// whether to have avatar
    fn has_avatar() -> bool;

    /// get the binary data of avatar
    fn get_avatar() -> Future<Result<OptionBuffer>>;
    // recommended server to try to join via
    fn via_server_name() -> Option<string>;
}

object SpaceHierarchyListResult {
    /// to be used for the next `since`
    fn next_batch() -> Option<string>;
    /// get the chunk of items in this response
    fn rooms() -> Future<Result<Vec<SpaceHierarchyRoomInfo>>>;
}

object SpaceRelation {
    /// the room ID this Relation links to
    fn room_id() -> RoomId;
    /// is this a suggested room?
    fn suggested() -> bool;
    /// how to find this room
    fn via() -> Vec<string>;
    /// of what type is the targeted room?
    fn target_type() -> string;
}

object SpaceRelations {
    //fn room_id() -> OwnedRoomId;
    fn room_id_str() -> string;
    /// do we have a canonical parent?!?
    fn main_parent() -> Option<SpaceRelation>;
    /// other parents we belong to
    fn other_parents() -> Vec<SpaceRelation>;
    /// children
    fn children() -> Vec<SpaceRelation>;
    /// query for children from the server
    fn query_hierarchy(from: Option<string>) -> Future<Result<SpaceHierarchyListResult>>;
}

object Space {
    /// get the room profile that contains avatar and display name
    fn get_profile() -> RoomProfile;

    /// get the room profile that contains avatar and display name
    fn space_relations() -> Future<Result<SpaceRelations>>;

    /// Whether this space is a child of the given space
    fn is_child_space_of(room_id: string) -> Future<bool>;

    /// add the following as a child space
    fn add_child_space(room_id: string) -> Future<Result<string>>;

    /// Change the avatar of the room
    fn upload_avatar(uri: string) -> Future<Result<MxcUri>>;

    fn set_acter_space_states() -> Future<Result<bool>>;

    /// Remove the avatar of the room
    fn remove_avatar() -> Future<Result<EventId>>;

    /// what is the description / topic
    fn topic() -> Option<string>;

    fn is_joined() -> bool;

    /// set description / topic of the room
    fn set_topic(topic: string) -> Future<Result<EventId>>;

    /// set name of the room
    fn set_name(name: Option<string>) -> Future<Result<EventId>>;

    /// the members currently in the space
    fn active_members() -> Future<Result<Vec<Member>>>;

    /// the members invited to this room
    fn invited_members() -> Future<Result<Vec<Member>>>;

    /// the room id
    fn get_room_id() -> RoomId;

    /// invite the new user to this space
    fn invite_user(user_id: string) -> Future<Result<bool>>;

    /// the room id as str
    fn get_room_id_str() -> string;

    /// the members currently in the room
    fn get_member(user_id: string) -> Future<Result<Member>>;

    /// the Membership of myself
    fn get_my_membership() -> Future<Result<Member>>;

    /// whether this room is encrypted one
    fn is_encrypted() -> Future<Result<bool>>;

    /// whether or not this space is public
    fn is_public() -> bool;

    /// join rules for this space.
    fn join_rule_str() -> string;

    /// the ids of the rooms the restriction applies to
    fn restricted_room_ids_str() -> Vec<string>;

    /// whether or not this space has been marked as an 'acter' one
    fn is_acter_space() -> Future<Result<bool>>;

    /// the Tasks lists of this Space
    fn task_lists() -> Future<Result<Vec<TaskList>>>;

    /// the Tasks list of this Space
    fn task_list(key: string) -> Future<Result<TaskList>>;

    /// task list draft builder
    fn task_list_draft() -> Result<TaskListDraft>;

    /// get latest news
    fn latest_news_entries(count: u32) -> Future<Result<Vec<NewsEntry>>>;

    /// get all calendar events
    fn calendar_events() -> Future<Result<Vec<CalendarEvent>>>;

    /// create calendart event draft
    fn calendar_event_draft() -> Result<CalendarEventDraft>;

    /// create news draft
    fn news_draft() -> Result<NewsEntryDraft>;

    /// the pins of this Space
    fn pins() -> Future<Result<Vec<ActerPin>>>;

    /// the links pinned to this Space
    fn pinned_links() -> Future<Result<Vec<ActerPin>>>;

    /// pin draft builder
    fn pin_draft() -> Result<PinDraft>;

    /// send the image message to this room
    fn send_image_message(uri: string, name: string, mimetype: string, size: Option<u32>, width: Option<u32>, height: Option<u32>, blurhash: Option<string>) -> Future<Result<EventId>>;

    /// decrypted image buffer data
    /// The reason that this function belongs to room object is because ChatScreen keeps it as member variable
    /// If this function belongs to message object, we may have to load too many message objects in ChatScreen
    fn image_binary(event_id: string) -> Future<Result<buffer<u8>>>;

    /// send the audio message to this room
    fn send_audio_message(uri: string, name: string, mimetype: string, secs: Option<u32>, size: Option<u32>) -> Future<Result<EventId>>;

    /// decrypted audio buffer data
    /// The reason that this function belongs to room object is because ChatScreen keeps it as member variable
    /// If this function belongs to message object, we may have to load too many message objects in ChatScreen
    fn audio_binary(event_id: string) -> Future<Result<buffer<u8>>>;

    /// send the video message to this room
    fn send_video_message(uri: string, name: string, mimetype: string, secs: Option<u32>, height: Option<u32>, width: Option<u32>, size: Option<u32>, blurhash: Option<string>) -> Future<Result<EventId>>;

    /// decrypted video buffer data
    /// The reason that this function belongs to room object is because ChatScreen keeps it as member variable
    /// If this function belongs to message object, we may have to load too many message objects in ChatScreen
    fn video_binary(event_id: string) -> Future<Result<buffer<u8>>>;

    /// send the file message to this room
    fn send_file_message(uri: string, name: string, mimetype: string, size: u32) -> Future<Result<EventId>>;

    /// decrypted file buffer data
    /// The reason that this function belongs to room object is because ChatScreen keeps it as member variable
    /// If this function belongs to message object, we may have to load too many message objects in ChatScreen
    fn file_binary(event_id: string) -> Future<Result<buffer<u8>>>;

    /// join this room
    fn join() -> Future<Result<bool>>;

    /// leave this room
    fn leave() -> Future<Result<bool>>;
    
    /// update the power levels of specified member
    fn update_power_level(user_id: string, level: i32) -> Future<Result<EventId>>;

}

enum MembershipStatus {
    Admin,
    Mod,
    Custom,
    Regular
}

enum MemberPermission {
    CanSendChatMessages,
    CanSendReaction,
    CanSendSticker,
    CanPostNews,
    CanPostPin,
    CanBan,
    CanKick,
    CanInvite,
    CanRedact,
    CanTriggerRoomNotification,
    CanUpgradeToActerSpace,
    CanSetName,
    CanUpdateAvatar,
    CanSetTopic,
    CanLinkSpaces,
    CanUpdatePowerLevels,
    CanSetParentSpace
}

object Member {
    /// get the user profile that contains avatar and display name
    fn get_profile() -> UserProfile;

    /// Full user_id
    fn user_id() -> UserId;

    /// The status of this member.
    fn membership_status_str() -> string;

    /// the power level this user has
    fn power_level() -> u64;

    /// Whether this user is allowed to perform the given action
    //fn can(permission: MemberPermission) -> bool;
    fn can_string(permission: string) -> bool;
}

object Account {
    /// get user id of this account
    fn user_id() -> UserId;

    /// The display_name of the account
    fn display_name() -> Future<Result<OptionString>>;

    /// Change the display name of the account
    fn set_display_name(name: string) -> Future<Result<bool>>;

    /// The avatar of the client
    fn avatar() -> Future<Result<OptionBuffer>>;

    /// Change the avatar of the account with the provided
    /// local file path
    fn upload_avatar(uri: string) -> Future<Result<MxcUri>>;
}

object SyncState {
    /// Get event handler of first synchronization on every launch
    fn first_synced_rx() -> Stream<bool>;

    /// When the sync stopped with an error, this will trigger
    fn sync_error_rx() -> Stream<string>;

    /// stop the sync loop
    fn cancel();
}

object PublicSearchResultItem {
    fn name() -> Option<string>;
    fn topic() -> Option<string>;
    fn world_readable() -> bool;
    fn guest_can_join() -> bool;
    // fn canonical_alias() -> Option<OwnedRoomAliasId>;
    fn canonical_alias_str() -> Option<string>;
    fn num_joined_members() -> u64;
    // fn room_id() -> OwnedRoomId;
    fn room_id_str() -> string;
    // fn avatar_url() -> Option<OwnedMxcUri>;
    fn avatar_url_str() -> Option<string>;
    // fn join_rule() -> PublicRoomJoinRule;
    fn join_rule_str() -> string;
    // fn room_type() -> Option<RoomType>;
    fn room_type_str() -> string;
}

object PublicSearchResult {
    /// to be used for the next `since`
    fn next_batch() -> Option<string>;
    /// to get the previous page
    fn prev_batch() -> Option<string>;
    /// an estimated total of matches
    fn total_room_count_estimate() -> Option<u64>;
    /// get the chunk of items in this response
    fn chunks() -> Vec<PublicSearchResultItem>;
}

object Notification {
    fn read() -> bool;
    // fn room_id() -> OwnedRoomId;
    fn room_id_str() -> string;
    fn has_room() -> bool;
    fn is_space() -> bool;
    fn is_acter_space() -> bool;
    fn space() -> Option<Space>;
    fn room_message() -> Option<RoomMessage>;
    fn convo() -> Option<Convo>;
}

object NotificationListResult {
    /// to be used for the next `since`
    fn next_batch() -> Option<string>;
    /// get the chunk of items in this response
    fn notifications() -> Future<Result<Vec<Notification>>>;
}

/// make convo settings builder
fn new_convo_settings_builder() -> CreateConvoSettingsBuilder;

object CreateConvoSettingsBuilder {
    /// set the name of convo
    fn set_name(value: string);

    /// set the alias of convo
    fn set_alias(value: string);

    /// append user id that will be invited to this space
    fn add_invitee(value: string) -> Result<()>;

    /// set the topic of convo
    fn set_topic(value: string);

    /// set the avatar uri of convo
    /// both remote and local are allowed
    fn set_avatar_uri(value: string);

    /// set the parent of convo
    fn set_parent(value: string);

    fn build() -> CreateConvoSettings;
}

object CreateConvoSettings {}

/// make space settings builder
fn new_space_settings_builder() -> CreateSpaceSettingsBuilder;

object CreateSpaceSettingsBuilder {
    /// set the name of convo
    fn set_name(value: string);

    /// set the space's visibility to either Public or Private
    fn set_visibility(value: string);

    /// append user id that will be invited to this space
    fn add_invitee(value: string) -> Result<()>;

    /// set the alias of space
    fn set_alias(value: string);

    /// set the topic of space
    fn set_topic(value: string);

    /// set the avatar uri of space
    /// both remote and local are allowed
    fn set_avatar_uri(value: string);

    /// set the parent of space
    fn set_parent(value: string);

    fn build() -> CreateSpaceSettings;
}

object CreateSpaceSettings {}

/// Main entry point for `acter`.
object Client {
    // Special

    /// start the sync
    fn start_sync() -> SyncState;

    /// Get the restore token for this session
    fn restore_token() -> Future<Result<string>>;

    /// Whether the client is registered as a guest account
    fn is_guest() -> bool;

    /// Whether the client has finished a first sync run
    fn has_first_synced() -> bool;

    /// Whether the client is syncing
    fn is_syncing() -> bool;

    /// Whether the client is logged in
    fn logged_in() -> bool;

    /// return the account of the logged in user, if given
    fn account() -> Result<Account>;

    /// The device_id of the client
    fn device_id() -> Result<DeviceId>;

    /// The user_id of the client
    /// deprecated, please use account() instead.
    fn user_id() -> Result<UserId>;

    /// get convo room
    fn convo(room_id_or_alias: string) -> Future<Result<Convo>>;

    /// get the user profile that contains avatar and display name
    fn get_user_profile() -> Result<UserProfile>;

    /// upload file and return remote url
    fn upload_media(uri: string) -> Future<Result<MxcUri>>;

    /// The convos the user is involved in
    fn convos() -> Future<Result<Vec<Convo>>>;

    /// The update event of convos the user is involved in
    fn convos_rx() -> Stream<Vec<Convo>>;

    /// The spaces the user is part of
    fn spaces() -> Future<Result<Vec<Space>>>;

    /// attempt to join a space
    fn join_space(room_id_or_alias: string, server_name: Option<string>) -> Future<Result<Space>>;

    /// attempt to join a room
    fn join_convo(room_id_or_alias: string, server_name: Option<string>) -> Future<Result<Convo>>;

    /// search the public directory for spaces
    fn public_spaces(search_term: Option<string>, server: Option<string>, since: Option<string>) -> Future<Result<PublicSearchResult>>;

    /// Get the space that user belongs to
    fn get_space(room_id_or_alias: string) -> Future<Result<Space>>;

    /// Get the Pinned Links for the client
    fn pinned_links() -> Future<Result<Vec<ActerPin>>>;

    /// Get the invitation event stream
    fn invitations_rx() -> Stream<Vec<Invitation>>;

    /// the users out of room
    fn suggested_users_to_invite(room_name: string) -> Future<Result<Vec<UserProfile>>>;

    /// search the user directory
    fn search_users(search_term: string) -> Future<Result<Vec<UserProfile>>>;

    /// Whether the user already verified the device
    fn verified_device(dev_id: string) -> Future<Result<bool>>;

    /// log out this client
    fn logout() -> Future<Result<bool>>;

    /// Get the verification event receiver
    fn verification_event_rx() -> Option<Stream<VerificationEvent>>;

    /// Get session manager that returns all/verified/unverified/inactive session list
    fn session_manager() -> SessionManager;

    /// Return the event handler of device changed
    fn device_changed_event_rx() -> Option<Stream<DeviceChangedEvent>>;

    /// Return the event handler of device left
    fn device_left_event_rx() -> Option<Stream<DeviceLeftEvent>>;

    /// Return the typing event receiver
    fn typing_event_rx() -> Option<Stream<TypingEvent>>;

    /// Return the receipt event receiver
    fn receipt_event_rx() -> Option<Stream<ReceiptEvent>>;

    /// create convo
    fn create_convo(settings: CreateConvoSettings) -> Future<Result<RoomId>>;

    /// create default space
    fn create_acter_space(settings: CreateSpaceSettings) -> Future<Result<RoomId>>;

    /// listen to updates to any model key
    fn subscribe_stream(key: string) -> Stream<bool>;

    /// Fetch the Comment or use its event_id to wait for it to come down the wire
    fn wait_for_comment(key: string, timeout: Option<EfkDuration>) -> Future<Result<Comment>>;

    /// Fetch the NewsEntry or use its event_id to wait for it to come down the wire
    fn wait_for_news(key: string, timeout: Option<EfkDuration>) -> Future<Result<NewsEntry>>;

    /// Get the latest News for the client
    fn latest_news_entries(count: u32) -> Future<Result<Vec<NewsEntry>>>;

    /// Fetch the ActerPin or use its event_id to wait for it to come down the wire
    fn wait_for_pin(key: string, timeout: Option<EfkDuration>) -> Future<Result<ActerPin>>;

    /// Get the Pins for the client
    fn pins() -> Future<Result<Vec<ActerPin>>>;

    /// Get a specific Pin for the client
    fn pin(pin_id: string) -> Future<Result<ActerPin>>;

    /// Fetch the Tasklist or use its event_id to wait for it to come down the wire
    fn wait_for_task_list(key: string, timeout: Option<EfkDuration>) -> Future<Result<TaskList>>;

    /// the Tasks lists for the client
    fn task_lists() -> Future<Result<Vec<TaskList>>>;

    /// Fetch the Task or use its event_id to wait for it to come down the wire
    fn wait_for_task(key: string, timeout: Option<EfkDuration>) -> Future<Result<Task>>;

    /// the Tasks list for the client
    fn task_list(key: string) -> Future<Result<TaskList>>;

    /// get all calendar events
    fn calendar_events() -> Future<Result<Vec<CalendarEvent>>>;

    /// Get a specific Calendar Event for the client
    fn calendar_event(calendar_id: string) -> Future<Result<CalendarEvent>>;

    /// Fetch the calendar event or use its event_id to wait for it to come down the wire
    fn wait_for_calendar_event(key: string, timeout: Option<EfkDuration>) -> Future<Result<CalendarEvent>>;

    /// list the currently queued notifications
    fn list_notifications(since: Option<string>, only: Option<string>) -> Future<Result<NotificationListResult>>;

    /// listen to incoming notifications
    fn notifications_stream() -> Stream<Notification>;

}

object OptionString {
    /// get text
    fn text() -> Option<string>;
}

object OptionBuffer {
    /// get text
    fn data() -> Option<buffer<u8>>;
}

object UserProfile {
    /// get user id
    fn user_id() -> UserId;

    /// whether to have avatar
    fn has_avatar() -> Future<Result<bool>>;

    /// get the binary data of avatar
    fn get_avatar() -> Future<Result<OptionBuffer>>;

    /// get the binary data of thumbnail
    fn get_thumbnail(width: u32, height: u32) -> Future<Result<OptionBuffer>>;

    /// get the display name
    fn get_display_name() -> Future<Result<OptionString>>;
}

object RoomProfile {
    /// whether to have avatar
    fn has_avatar() -> Result<bool>;

    /// get the binary data of avatar
    fn get_avatar() -> Future<Result<OptionBuffer>>;

    /// get the binary data of thumbnail
    fn get_thumbnail(width: u32, height: u32) -> Future<Result<OptionBuffer>>;

    /// get the display name
    fn get_display_name() -> Future<Result<OptionString>>;
}

object Invitation {
    /// get the timestamp of this invitation in milliseconds
    fn origin_server_ts() -> Option<u64>;

    /// get the room id of this invitation
    fn room_id() -> RoomId;

    /// get the room name of this invitation
    fn room_name() -> Future<Result<string>>;

    /// get the user id of this invitation sender
    fn sender() -> UserId;

    /// get the user profile that contains avatar and display name
    fn get_sender_profile() -> Future<Result<UserProfile>>;

    /// accept invitation about me to this room
    fn accept() -> Future<Result<bool>>;

    /// reject invitation about me to this room
    fn reject() -> Future<Result<bool>>;
}

object VerificationEvent {
    /// Get event type
    fn event_type() -> string;

    /// Get flow id (EventId or TransactionId)
    fn flow_id() -> Option<string>;

    /// Get user id of event sender
    fn sender() -> string;

    /// Get content by field
    fn get_content(key: string) -> Option<string>;

    /// Get emoji array
    fn get_emojis() -> Vec<VerificationEmoji>;

    /// Bob accepts the verification request from Alice
    fn accept_verification_request() -> Future<Result<bool>>;

    /// Bob cancels the verification request from Alice
    fn cancel_verification_request() -> Future<Result<bool>>;

    /// Bob accepts the verification request from Alice with specified methods
    fn accept_verification_request_with_methods(methods: Vec<string>) -> Future<Result<bool>>;

    /// Alice starts the SAS verification
    fn start_sas_verification() -> Future<Result<bool>>;

    /// Whether verification request was launched from this device
    fn was_triggered_from_this_device() -> Result<bool>;

    /// Bob accepts the SAS verification
    fn accept_sas_verification() -> Future<Result<bool>>;

    /// Bob cancels the SAS verification
    fn cancel_sas_verification() -> Future<Result<bool>>;

    /// Alice sends the verification key to Bob and vice versa
    fn send_verification_key() -> Future<Result<bool>>;

    /// Alice says to Bob that SAS verification matches and vice versa
    fn confirm_sas_verification() -> Future<Result<bool>>;

    /// Alice says to Bob that SAS verification doesn't match and vice versa
    fn mismatch_sas_verification() -> Future<Result<bool>>;

    /// Alice and Bob reviews the AnyToDeviceEvent::KeyVerificationMac
    fn review_verification_mac() -> Future<Result<bool>>;
}

object VerificationEmoji {
    /// binary representation of emoji unicode
    fn symbol() -> u32;

    /// text description of emoji unicode
    fn description() -> string;
}

object SessionManager {
    fn all_sessions() -> Future<Result<Vec<DeviceRecord>>>;

    /// Force to logout another devices
    /// Authentication is required to do so
    fn delete_devices(dev_ids: Vec<string>, username: string, password: string) -> Future<Result<bool>>;

    /// Trigger verification of another device
    fn request_verification(dev_id: string) -> Future<Result<bool>>;
}

/// Deliver receipt event from rust to flutter
object ReceiptEvent {
    /// Get transaction id or flow id
    fn room_id() -> RoomId;

    /// Get records
    fn receipt_records() -> Vec<ReceiptRecord>;
}

/// Deliver receipt record from rust to flutter
object ReceiptRecord {
    /// Get id of event that this user read message from peer
    fn event_id() -> string;

    /// Get id of user that read this message
    fn seen_by() -> string;

    /// Get time that this user read message from peer in milliseconds
    fn ts() -> Option<u64>;
}

/// Deliver devices changed event from rust to flutter
object DeviceChangedEvent {
    /// Get the device list, excluding verified ones
    fn device_records(verified: bool) -> Future<Result<Vec<DeviceRecord>>>;

    /// Request verification to any devices of user
    fn request_verification_to_user() -> Future<Result<bool>>;

    /// Request verification to specific device
    fn request_verification_to_device(dev_id: string) -> Future<Result<bool>>;

    /// Request verification to any devices of user with methods
    fn request_verification_to_user_with_methods(methods: Vec<string>) -> Future<Result<bool>>;

    /// Request verification to specific device with methods
    fn request_verification_to_device_with_methods(dev_id: string, methods: Vec<string>) -> Future<Result<bool>>;
}

/// Deliver devices left event from rust to flutter
object DeviceLeftEvent {
    /// Get the device list, including deleted ones
    fn device_records(deleted: bool) -> Future<Result<Vec<DeviceRecord>>>;
}

/// Provide various device infos
object DeviceRecord {
    /// get the id of this device
    fn device_id() -> DeviceId;

    /// get the display name of this device
    fn display_name() -> Option<string>;

    /// last seen ip of this device
    fn last_seen_ip() -> Option<string>;

    /// last seen timestamp of this device in milliseconds
    fn last_seen_ts() -> Option<u64>;

    /// whether it was verified
    fn is_verified() -> bool;

    /// whether it is active
    fn is_active() -> bool;
}

/// Deliver typing event from rust to flutter
object TypingEvent {
    /// Get transaction id or flow id
    fn room_id() -> RoomId;

    /// Get list of user id
    fn user_ids() -> Vec<UserId>;
}
