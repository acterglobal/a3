/// Initialize logging
fn init_logging(filter: Option<string>) -> Result<()>;

/// Create a new client for homeserver at url with storage at data_path
fn login_new_client(basepath: string, username: string, password: string, device_name: Option<string>) -> Future<Result<Client>>;

/// Create a new client from the restore token
fn login_with_token(basepath: string, restore_token: string) -> Future<Result<Client>>;

/// Create a new client anonymous client connecting to the homeserver
fn guest_client(basepath: string, homeserver: string, device_name: Option<string>) -> Future<Result<Client>>;

/// Create a new client from the restore token
fn register_with_registration_token(basepath: string, username: string, password: string, registration_token: string, device_name: Option<string>) -> Future<Result<Client>>;

/// generate news mock items
fn gen_mock_news() -> Vec<News>;

/// Representing a color
object Color {
    /// as rgba in u8
    fn rgba_u8() -> (u8, u8, u8, u8);
}

/// A news object
object News {
    /// get the text of the news item
    fn text() -> Option<string>;
    /// the tags on this item
    fn tags() -> Vec<Tag>;
    /// the number of likes on this item
    fn likes_count() -> u32;
    /// the number of comments on this item
    fn comments_count() -> u32;
    /// if given, the specific foreground color
    fn fg_color() -> Option<Color>; 
    /// if given, the specific background color
    fn bg_color() -> Option<Color>; 
    /// if given, the image
    fn image() -> Option<Vec<u8>>; 
}

object Tag {
    /// the title of the tag
    fn title() -> string;
    /// dash-cased-ascii-version for usage in hashtags (no `#` at the front)
    fn hash_tag() -> string;
    /// if given, the specific color for this tag
    fn color() -> Option<Color>; 
}

/// A news object
object Faq {
    /// get the title of the news item
    fn title() -> string;
    /// get the body of the news item
    fn body() -> string;
    /// whether this object is pinned
    fn pinned() -> bool;
    // The team this faq belongs to
    //fn team() -> Room;
    /// the tags on this item
    fn tags() -> Vec<Tag>;
    /// the number of likes on this item
    fn likes_count() -> u32;
    /// the number of comments on this item
    fn comments_count() -> u32;
}

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
object RoomMessage {
    /// Unique ID of this event
    fn event_id() -> string;

    /// room ID of this event
    fn room_id() -> string;

    /// The User, who sent that event
    fn sender() -> string;

    /// the body of the massage - fallback string reprensentation
    fn body() -> string;

    /// get html body
    fn formatted_body() -> Option<string>;

    /// the server receiving timestamp in milliseconds
    fn origin_server_ts() -> Option<u64>;

    /// the type of massage, like audio, text, image, file, etc
    fn msgtype() -> string;

    /// contains source data, name, mimetype, size, width and height
    fn image_description() -> Option<ImageDescription>;

    /// contains source data, name, mimetype and size
    fn file_description() -> Option<FileDescription>;
}

object ImageDescription {

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
}

object FileDescription {

    /// file name
    fn name() -> string;

    /// MIME
    fn mimetype() -> Option<string>;

    /// file size in bytes
    fn size() -> Option<u64>;
}

/// Timeline with Room Events
object TimelineStream {
    /// Fires whenever a new event arrived
    fn next() -> Future<Result<RoomMessage>>;

    /// Get the next count messages backwards,
    fn paginate_backwards(count: u32) -> Future<Result<Vec<RoomMessage>>>;
}

object Conversation {
    /// get the room profile that contains avatar and display name
    fn get_profile() -> Future<Result<RoomProfile>>;

    /// the members currently in the room
    fn active_members() -> Future<Result<Vec<Member>>>;

    /// Get the timeline for the room
    fn timeline() -> Result<TimelineStream>;

    /// get the room member by user id
    fn get_member(user_id: string) -> Future<Result<Member>>;

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

    /// invite the new user to this room
    fn invite_user(user_id: string) -> Future<Result<bool>>;

    /// get the user status on this room
    fn room_type() -> string;

    /// join this room
    fn join() -> Future<Result<bool>>;

    /// leave this room
    fn leave() -> Future<Result<bool>>;

    /// get the users that were invited to this room
    fn get_invitees() -> Future<Result<Vec<Account>>>;

    /// Send a text message in MarkDown format to the room
    fn send_formatted_message(markdown_message: string) -> Future<Result<string>>;

    /// send the image message to this room
    fn send_image_message(uri: string, name: string, mimetype: string, size: Option<u32>, width: Option<u32>, height: Option<u32>) -> Future<Result<string>>;

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
}

object Group {
    /// get the room profile that contains avatar and display name
    fn get_profile() -> Future<Result<RoomProfile>>;

    /// the members currently in the group
    fn active_members() -> Future<Result<Vec<Member>>>;

    // the members currently in the room
    fn get_member(user_id: string) -> Future<Result<Member>>;
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
}

/// Main entry point for `effektio`.
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

    /// Get the FAQs for the client
    fn faqs() -> Future<Result<Vec<Faq>>>;

    /// Get the invitation event stream
    fn invitations_rx() -> Stream<Vec<Invitation>>;

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
}

object UserProfile {
    /// whether to have avatar
    fn has_avatar() -> bool;

    /// get the binary data of avatar
    fn get_avatar() -> Future<Result<buffer<u8>>>;

    /// get the display name
    fn get_display_name() -> Option<string>;
}

object RoomProfile {
    /// whether to have avatar
    fn has_avatar() -> bool;

    /// get the binary data of avatar
    fn get_avatar() -> Future<Result<buffer<u8>>>;

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
    fn flow_id() -> string;

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
