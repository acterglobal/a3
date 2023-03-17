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
fn register_with_token(basepath: string, username: string, password: string, registration_token: string, default_homeserver_name: string, default_homeserver_url: string, device_name: Option<string>) -> Future<Result<Client>>;

/// generate news mock items
fn gen_mock_news() -> Vec<News>;

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
}

/// A news object
object News {
    /// the id of this news
    fn id() -> string;
    /// get the text of the news item
    fn text() -> Option<string>;
    /// the tags on this item
    fn tags() -> Vec<Tag>;
    /// the number of likes on this item
    fn likes_count() -> u32;
    /// the number of comments on this item
    fn comments_count() -> u32;
    /// if given, the specific foreground color
    fn fg_color() -> Option<EfkColor>; 
    /// if given, the specific background color
    fn bg_color() -> Option<EfkColor>; 
    /// if given, the image
    fn image() -> Option<Vec<u8>>;
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
    fn unset_content();

    /// set the url for this pin
    fn url(text: string);
    fn unset_url();

    // fire this pin over - the event_id is the confirmation
    // from the server.
    fn send() -> Future<Result<EventId>>;
}

/// A pin object
object ActerPin {
    /// get the title of the pin
    fn title() -> string;
    /// get the content_text of the pin
    fn content_text() -> Option<string>;
    /// whether this pin is a link
    fn is_link() -> bool;
    /// get the link content
    fn url() -> Option<string>;
    /// get the link color settings
    fn color() -> Option<EfkColor>;
    // The room this Pin belongs to
    //fn team() -> Room;

    /// make a builder for updating the pin
    fn update_builder() -> Result<PinUpdateBuilder>;

    // get informed about changes to this pin
    fn subscribe() -> Stream<()>;

    /// replace the current pin with one with the latest state
    fn refresh() -> Future<Result<ActerPin>>;

    // get the comments manager for this pin
    // fn comments() -> Future<Result<CommentsManager>>;
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

    // fire this update over - the event_id is the confirmation
    // from the server.
    fn send() -> Future<Result<EventId>>;

}

object MediaSource {}

object DeviceId {
    fn to_string() -> string;
}

object EventId {
    fn to_string() -> string;
}

object RoomId {
    fn to_string() -> string;
}

object UserId {
    // full name as string
    //fn as_str() -> string;

    fn to_string() -> string;

    // only the user name itself
    //fn localpart() -> string;
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

    /// the type of massage, like audio, text, image, file, etc
    fn msgtype() -> Option<string>;

    /// contains text fallback and formatted text
    fn text_desc() -> Option<TextDesc>;

    /// contains source data, name, mimetype, size, width and height
    fn image_desc() -> Option<ImageDesc>;

    /// contains source data, name, mimetype, size, width and height
    fn video_desc() -> Option<VideoDesc>;

    /// contains source data, name, mimetype and size
    fn file_desc() -> Option<FileDesc>;

    /// original event id, if this msg is reply to another msg
    fn in_reply_to() -> Option<string>;

    /// the emote key list that users reacted about this message
    fn reaction_keys() -> Vec<string>;

    /// the details that users reacted using this emote key in this message
    fn reaction_desc(key: string) -> Option<ReactionDesc>;

    /// Whether this message is editable
    fn is_editable() -> bool;
}

object RoomVirtualItem {
    /// one of DayDivider/LoadingIndicator/ReadMarker/TimelineStart
    fn event_type() -> string;

    /// contains description text
    fn desc() -> Option<string>;
}

/// A room Message metadata and content
object RoomMessage {
    /// one of event/virtual
    fn item_type() -> string;

    /// room ID of this event
    fn room_id() -> string;

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

    /// MIME
    fn mimetype() -> Option<string>;

    /// file size in bytes
    fn size() -> Option<u64>;

    /// image width
    fn width() -> Option<u64>;

    /// image height
    fn height() -> Option<u64>;

    /// thumbnail mimetype
    fn thumbnail_mimetype() -> Option<string>;

    /// thumbnail file size
    fn thumbnail_size() -> Option<u64>;

    /// thumbnail image width
    fn thumbnail_width() -> Option<u64>;

    /// thumbnail image height
    fn thumbnail_height() -> Option<u64>;

    /// thumbnail source
    fn thumbnail_source() -> Option<MediaSource>;
}

object VideoDesc {
    /// file name
    fn name() -> string;

    /// MIME
    fn mimetype() -> Option<string>;

    /// file size in bytes
    fn size() -> Option<u64>;

    /// image width
    fn width() -> Option<u64>;

    /// image height
    fn height() -> Option<u64>;

    /// blurhash
    fn blurhash() -> Option<string>;

    /// duration in seconds
    fn duration() -> Option<u64>;

    /// thumbnail mimetype
    fn thumbnail_mimetype() -> Option<string>;

    /// thumbnail file size
    fn thumbnail_size() -> Option<u64>;

    /// thumbnail image width
    fn thumbnail_width() -> Option<u64>;

    /// thumbnail image height
    fn thumbnail_height() -> Option<u64>;

    /// thumbnail source
    fn thumbnail_source() -> Option<MediaSource>;
}

object FileDesc {
    /// file name
    fn name() -> string;

    /// MIME
    fn mimetype() -> Option<string>;

    /// file size in bytes
    fn size() -> Option<u64>;

    /// thumbnail mimetype
    fn thumbnail_mimetype() -> Option<string>;

    /// thumbnail file size
    fn thumbnail_size() -> Option<u64>;

    /// thumbnail image width
    fn thumbnail_width() -> Option<u64>;

    /// thumbnail image height
    fn thumbnail_height() -> Option<u64>;

    /// thumbnail source
    fn thumbnail_source() -> Option<MediaSource>;
}

object ReactionDesc {
    /// how many times this key was clicked
    fn count() -> u64;

    /// which users selected this key
    fn senders() -> Vec<string>;
}

object TimelineDiff {
    /// Replace/InsertAt/UpdateAt/Push/RemoveAt/Move/Pop/Clear
    fn action() -> string;

    /// for Replace
    fn values() -> Option<Vec<RoomMessage>>;

    /// for InsertAt/UpdateAt/RemoveAt
    fn index() -> Option<usize>;

    /// for InsertAt/UpdateAt/Push
    fn value() -> Option<RoomMessage>;

    /// for Move
    fn new_index() -> Option<usize>;

    /// for Move
    fn old_index() -> Option<usize>;
}

/// Timeline with Room Events
object TimelineStream {
    /// Fires whenever new diff found
    fn diff_rx() -> Stream<TimelineDiff>;

    /// Fires whenever new event arrived
    fn next() -> Future<Result<RoomMessage>>;

    /// Get the next count messages backwards,
    fn paginate_backwards(count: u16) -> Future<Result<bool>>;

    /// modify the room message
    fn edit(new_msg: string, original_event_id: string, txn_id: Option<string>) -> Future<Result<bool>>;
}

object Conversation {
    /// get the room profile that contains avatar and display name
    fn get_profile() -> Future<Result<RoomProfile>>;

    /// the members currently in the room
    fn active_members() -> Future<Result<Vec<Member>>>;

    /// get the room member by user id
    fn get_member(user_id: string) -> Future<Result<Member>>;

    /// Get the timeline for the room
    fn timeline_stream() -> Future<Result<TimelineStream>>;

    /// The last message sent to the room
    fn latest_message() -> Option<RoomMessage>;

    /// the room id
    fn get_room_id() -> string;

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
    fn send_plain_message(text_message: string) -> Future<Result<string>>;

    /// Send a text message in MarkDown format to the room
    fn send_formatted_message(markdown_message: string) -> Future<Result<string>>;

    /// Send reaction about existing event
    fn send_reaction(event_id: string, key: string) -> Future<Result<string>>;

    /// send the image message to this room
    fn send_image_message(uri: string, name: string, mimetype: string, size: Option<u32>, width: Option<u32>, height: Option<u32>) -> Future<Result<string>>;

    /// get the user status on this room
    fn room_type() -> string;

    /// invite the new user to this room
    fn invite_user(user_id: string) -> Future<Result<bool>>;

    /// join this room
    fn join() -> Future<Result<bool>>;

    /// leave this room
    fn leave() -> Future<Result<bool>>;

    /// get the users that were invited to this room
    fn get_invitees() -> Future<Result<Vec<Account>>>;

    /// decrypted image file data
    /// The reason that this function belongs to room object is because ChatScreen keeps it as member variable
    /// If this function belongs to message object, we may have to load too many message objects in ChatScreen
    fn image_binary(event_id: string) -> Future<Result<buffer<u8>>>;

    /// send the file message to this room
    fn send_file_message(uri: string, name: string, mimetype: string, size: u32) -> Future<Result<string>>;

    /// save file in specified path
    fn save_file(event_id: string, dir_path: string) -> Future<Result<string>>;

    /// get the path that file was saved
    fn file_path(event_id: string) -> Future<Result<string>>;

    /// initially called to get receipt status of room members
    fn user_receipts() -> Future<Result<Vec<ReceiptRecord>>>;

    /// whether this room is encrypted one
    fn is_encrypted() -> Future<Result<bool>>;

    /// get original of reply msg
    fn get_message(event_id: string) -> Future<Result<RoomMessage>>;

    /// send reply as text
    fn send_text_reply(msg: string, event_id: string, txn_id: Option<string>) -> Future<Result<string>>;

    /// send reply as image
    fn send_image_reply(uri: string, name: string, mimetype: string, size: Option<u32>, width: Option<u32>, height: Option<u32>, event_id: string, txn_id: Option<string>) -> Future<Result<string>>;

    /// send reply as file
    fn send_file_reply(uri: string, name: string, mimetype: string, size: Option<u32>, event_id: string, txn_id: Option<string>) -> Future<Result<string>>;

    /// redact any message (including text/image/file and reaction)
    fn redact_message(event_id: string, reason: Option<string>, txn_id: Option<string>) -> Future<Result<string>>;
}

object CommentDraft {
    /// set the content of the draft to body
    fn content_text(body: string);

    /// set the content to a formatted body of html_body, where body is the tag-stripped version
    fn content_formatted(body: string, html_body: string);

    // fire this comment over - the event_id is the confirmation
    // from the server.
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

object Task {
    /// the name of this task
    fn title() -> string;

    /// the name of this task
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

    // get informed about changes to this task
    fn subscribe() -> Stream<()>;

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
    fn utc_due_from_rfc3339(utc_due: string) -> Result<bool>;
    /// set the utc_due for this task list in rfc2822 format
    fn utc_due_from_rfc2822(utc_due: string)-> Result<bool>;
    /// set the utc_due for this task list in custom format
    fn utc_due_from_format(utc_due: string, format: string)-> Result<bool>;
    fn unset_utc_due();
    fn unset_utc_due_update();

    /// set the utc_start for this task list in rfc3339 format
    fn utc_start_from_rfc3339(utc_start: string) -> Result<bool>;
    /// set the utc_start for this task list in rfc2822 format
    fn utc_start_from_rfc2822(utc_start: string)-> Result<bool>;
    /// set the utc_start for this task list in custom format
    fn utc_start_from_format(utc_start: string, format: string)-> Result<bool>;
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

    /// send this task update
    fn send() -> Future<Result<EventId>>;
}

object TaskDraft {
    /// set the title for this task
    fn title(title: string);

    /// set the description for this task list
    fn description_text(text: string);
    fn unset_description();

    /// set the sort order for this task list
    fn sort_order(sort_order: u32);

    /// set the color for this task list
    fn color(color: EfkColor);
    fn unset_color();

    /// set the utc_due for this task list in rfc3339 format
    fn utc_due_from_rfc3339(utc_due: string) -> Result<bool>;
    /// set the utc_due for this task list in rfc2822 format
    fn utc_due_from_rfc2822(utc_due: string)-> Result<bool>;
    /// set the utc_due for this task list in custom format
    fn utc_due_from_format(utc_due: string, format: string)-> Result<bool>;
    fn unset_utc_due();

    /// set the utc_start for this task list in rfc3339 format
    fn utc_start_from_rfc3339(utc_start: string) -> Result<bool>;
    /// set the utc_start for this task list in rfc2822 format
    fn utc_start_from_rfc2822(utc_start: string)-> Result<bool>;
    /// set the utc_start for this task list in custom format
    fn utc_start_from_format(utc_start: string, format: string)-> Result<bool>;
    fn unset_utc_start();

    /// set the sort order for this task list
    fn progress_percent(progress_percent: u8);
    fn unset_progress_percent();

    /// set the keywords for this task list
    fn keywords(keywords: Vec<string>);
    fn unset_keywords();
    /// set the categories for this task list
    fn categories(categories: Vec<string>);
    fn unset_categories();
    /// set the assignees for this task list
    fn assignees(assignees: Vec<UserId>);
    fn unset_assignees();
    /// set the subscribers for this task list
    fn subscribers(subscribers: Vec<UserId>);
    fn unset_subscribers();
    /// send this task list draft

    /// create this task
    fn send() -> Future<Result<EventId>>;
}

object TaskList {
    /// the name of this task list
    fn name() -> string;

    /// the name of this task list
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

    // get informed about changes to this task
    fn subscribe() -> Stream<()>;

    /// replace the current task with one with the latest state
    fn refresh() -> Future<Result<TaskList>>;
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
    /// send this task list draft
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
    /// send this task update
    fn send() -> Future<Result<EventId>>;
}

object Group {
    /// get the room profile that contains avatar and display name
    fn get_profile() -> Future<Result<RoomProfile>>;

    /// the members currently in the group
    fn active_members() -> Future<Result<Vec<Member>>>;

    /// the room id
    fn get_room_id() -> string;

    // the members currently in the room
    fn get_member(user_id: string) -> Future<Result<Member>>;

    /// whether this room is encrypted one
    fn is_encrypted() -> Future<Result<bool>>;

    /// the Tasks lists of this Group
    fn task_lists() -> Future<Result<Vec<TaskList>>>;

    /// task list draft builder
    fn task_list_draft() -> Result<TaskListDraft>;

    /// the pins of this Group
    fn pins() -> Future<Result<Vec<ActerPin>>>;

    /// the links pinned to this Group
    fn pinned_links() -> Future<Result<Vec<ActerPin>>>;

    /// pin draft builder
    fn pin_draft() -> Result<PinDraft>;
}

object Member {
    /// get the user profile that contains avatar and display name
    fn get_profile() -> Future<Result<UserProfile>>;

    /// Full user_id
    fn user_id() -> string;
}

object Account {
    /// get user id of this account
    fn user_id() -> string;

    /// The display_name of the account
    fn display_name() -> Future<Result<string>>;

    /// Change the display name of the account
    fn set_display_name(name: string) -> Future<Result<bool>>;

    /// The avatar of the client
    fn avatar() -> Future<Result<buffer<u8>>>;

    /// Change the avatar of the account
    /// provide the c_type as MIME, e.g. `image/jpeg`
    fn set_avatar(c_type: string, data: Vec<u8>) -> Future<Result<bool>>;
}

object SyncState {
    /// Get event handler of first synchronization on every launch
    fn first_synced_rx() -> Option<Stream<bool>>;

    /// stop the sync loop
    fn cancel();
}

object CreateGroupSettings {
    /// set the alias of group
    fn alias(value: string);

    /// set the group's visibility to either Public or Private
    fn visibility(value: string);

    /// add the id of user that will be invited to this group
    fn add_invitee(value: string);
}

fn new_group_settings(name: string) -> CreateGroupSettings;

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

    // The device_id of the client
    fn device_id() -> Result<string>;

    /// The user_id of the client
    /// deprecated, please use account() instead.
    fn user_id() -> Result<UserId>;

    /// get the user profile that contains avatar and display name
    fn get_user_profile() -> Future<Result<UserProfile>>;

    /// The conversations the user is involved in
    fn conversations() -> Future<Result<Vec<Conversation>>>;

    /// The update event of conversations the user is involved in
    fn conversations_rx() -> Stream<Vec<Conversation>>;

    /// The groups the user is part of
    fn groups() -> Future<Result<Vec<Group>>>;

    /// Get the following group the user is part of by
    /// roomId or room alias;
    fn get_group(id_or_alias: string) -> Future<Result<Group>>;

    /// Get the latest News for the client
    fn latest_news() -> Future<Result<Vec<News>>>;

    /// Get the Pins for the client
    fn pins() -> Future<Result<Vec<ActerPin>>>;

    /// Get the Pinned Links for the client
    fn pinned_links() -> Future<Result<Vec<ActerPin>>>;

    /// Get the invitation event stream
    fn invitations_rx() -> Stream<Vec<Invitation>>;

    /// the users out of room
    fn suggested_users_to_invite(room_name: string) -> Future<Result<Vec<UserProfile>>>;

    /// Whether the user already verified the device
    fn verified_device(dev_id: string) -> Future<Result<bool>>;

    /// log out this client
    fn logout() -> Future<Result<bool>>;

    /// Get the verification event receiver
    fn verification_event_rx() -> Option<Stream<VerificationEvent>>;

    /// Return the event handler of device changed
    fn device_changed_event_rx() -> Option<Stream<DeviceChangedEvent>>;

    /// Return the event handler of device left
    fn device_left_event_rx() -> Option<Stream<DeviceLeftEvent>>;

    /// Return the typing event receiver
    fn typing_event_rx() -> Option<Stream<TypingEvent>>;

    /// Return the receipt event receiver
    fn receipt_event_rx() -> Option<Stream<ReceiptEvent>>;

    /// Return the message receiver
    fn incoming_message_rx() -> Option<Stream<RoomMessage>>;

    /// the Tasks lists of this Group
    fn task_lists() -> Future<Result<Vec<TaskList>>>;

    /// create default group
    fn create_acter_group(settings: CreateGroupSettings) -> Future<Result<RoomId>>;

    /// listen to updates to any model key
    fn subscribe(key: string) -> Stream<bool>;

    /// Fetch the Comment or use its event_id to wait for it to come down the wire
    fn wait_for_comment(key: string, timeout: Option<EfkDuration>) -> Future<Result<Comment>>;

    /// Fetch the Tasklist or use its event_id to wait for it to come down the wire
    fn wait_for_task_list(key: string, timeout: Option<EfkDuration>) -> Future<Result<TaskList>>;

    /// Fetch the Task or use its event_id to wait for it to come down the wire
    fn wait_for_task(key: string, timeout: Option<EfkDuration>) -> Future<Result<Task>>;
}

object UserProfile {
    /// get user id
    fn user_id() -> UserId;

    /// whether to have avatar
    fn has_avatar() -> bool;

    /// get the binary data of avatar
    fn get_avatar() -> Future<Result<buffer<u8>>>;

    /// get the binary data of thumbnail
    fn get_thumbnail(width: u64, height: u64) -> Future<Result<buffer<u8>>>;

    /// get the display name
    fn get_display_name() -> Option<string>;
}

object RoomProfile {
    /// whether to have avatar
    fn has_avatar() -> bool;

    /// get the binary data of avatar
    fn get_avatar() -> Future<Result<buffer<u8>>>;

    /// get the binary data of thumbnail
    fn get_thumbnail(width: u64, height: u64) -> Future<Result<buffer<u8>>>;

    /// get the display name
    fn get_display_name() -> Option<string>;
}

object Invitation {
    /// get the timestamp of this invitation in milliseconds
    fn origin_server_ts() -> Option<u64>;

    /// get the room id of this invitation
    fn room_id() -> string;

    /// get the room name of this invitation
    fn room_name() -> string;

    /// get the user id of this invitation sender
    fn sender() -> string;

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

    /// An error code for why the process/request was cancelled by the user.
    fn cancel_code() -> Option<string>;

    /// A description for why the process/request was cancelled by the user.
    fn reason() -> Option<string>;

    /// Bob accepts the verification request from Alice
    fn accept_verification_request() -> Future<Result<bool>>;

    /// Bob cancels the verification request from Alice
    fn cancel_verification_request() -> Future<Result<bool>>;

    /// Bob accepts the verification request from Alice with specified methods
    fn accept_verification_request_with_methods(methods: Vec<string>) -> Future<Result<bool>>;

    /// Alice starts the SAS verification
    fn start_sas_verification() -> Future<Result<bool>>;

    /// Whether verification request was launched from this device
    fn was_triggered_from_this_device() -> Option<bool>;

    /// Bob accepts the SAS verification
    fn accept_sas_verification() -> Future<Result<bool>>;

    /// Bob cancels the SAS verification
    fn cancel_sas_verification() -> Future<Result<bool>>;

    /// Alice sends the verification key to Bob and vice versa
    fn send_verification_key() -> Future<Result<bool>>;

    /// Alice cancels the verification key from Bob and vice versa
    fn cancel_verification_key() -> Future<Result<bool>>;

    /// Alice gets the verification emoji from Bob and vice versa
    fn get_verification_emoji() -> Future<Result<Vec<VerificationEmoji>>>;

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

/// Deliver receipt event from rust to flutter
object ReceiptEvent {
    /// Get transaction id or flow id
    fn room_id() -> string;

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
    /// whether this device was verified
    fn verified() -> bool;

    /// whether this device was deleted
    fn deleted() -> bool;

    /// get the id of this device user
    fn user_id() -> string;

    /// get the id of this device
    fn device_id() -> string;

    /// get the display name of this device
    fn display_name() -> Option<string>;

    /// last seen ip of this device
    fn last_seen_ip() -> Option<string>;

    /// last seen timestamp of this device in milliseconds
    fn last_seen_ts() -> Option<u64>;
}

/// Deliver typing event from rust to flutter
object TypingEvent {
    /// Get transaction id or flow id
    fn room_id() -> string;

    /// Get list of user id
    fn user_ids() -> Vec<string>;
}
