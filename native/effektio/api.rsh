
/// Initialize logging
fn init_logging(filter: Option<string>) -> Result<()>;

/// Create a new client for homeserver at url with storage at data_path
fn login_new_client(basepath: string, username: string, password: string) -> Future<Result<Client>>;

/// Create a new client from the restore token
fn login_with_token(basepath: string, restore_token: string) -> Future<Result<Client>>;

/// Create a new client anonymous client connecting to the homeserver
fn guest_client(basepath: string, homeserver: string) -> Future<Result<Client>>;

object UserId {
    // full name as string
    //fn as_str() -> string;

    // only the user name itself
    //fn localpart() -> string;
}
object EventId {}

/// A room Message metadata and content
object RoomMessage {

    /// Unique ID of this event
    fn event_id() -> string;

    /// The User, who sent that event
    fn sender() -> string;

    /// the body of the massage - fallback string reprensentation
    fn body() -> string;

    /// the server receiving timestamp
    fn origin_server_ts() -> u64;
}

/// Timeline with Room Events
object TimelineStream {
    /// Fires whenever a new event arrived
    fn next() -> Future<Result<RoomMessage>>;

    /// Get the next count messages backwards,
    fn paginate_backwards(count: u64) -> Future<Result<Vec<RoomMessage>>>;
}

object Room {
    /// Calculate the display name
    fn display_name() -> Future<Result<string>>;

    /// The avatar of the room
    fn avatar() -> Future<Result<buffer<u8>>>;

    /// the members currently in the room
    fn active_members() -> Future<Result<Vec<RoomMember>>>;

    /// Get the timeline for the room
    fn timeline() -> Future<Result<TimelineStream>>;

    // the members currently in the room
    // fn get_member(user: UserId) -> Future<Result<RoomMember>>;

    /// The last message sent to the room
    fn latest_message() -> Future<Result<RoomMessage>>;

    /// Activate typing notice for this room
    /// The typing notice remains active for 4s. It can be deactivate at any
    /// point by setting typing to false. If this method is called while the
    /// typing notice is active nothing will happen. This method can be called
    /// on every key stroke, since it will do nothing while typing is active.
    fn typing_notice(typing: bool) -> Future<Result<()>>;

    /// Send a request to notify this room that the user has read specific event.
    fn read_receipt(event_id: string) -> Future<Result<()>>;

    /// Send a simple plain text message to the room
    /// returns the event_id as given by the server of the event soon after
    /// received over timeline().next()
    fn send_plain_message(text_message: string) -> Future<Result<string>>;
}

object RoomMember {

    /// The avatar of the member
    fn avatar() -> Future<Result<buffer<u8>>>;

    /// Calculate the display name
    fn display_name() -> Option<string>;

    /// Falback name
    // fn name() -> string;

    /// Full user_id
    fn user_id() -> UserId;

}

/// Main entry point for `effektio`.
object Client {
    // Special

    /// Get the restore token for this session
    fn restore_token() -> Future<Result<string>>;

    /// Whether the client is registered as a guest account
    fn is_guest() -> bool;

    /// Whether the client has finished a first sync run
    fn has_first_synced() -> bool;

    /// Whether the client is syncing
    fn is_syncing() -> bool;

    // Regular Rust Matrix Client
    /// Whether the client is logged in
    fn logged_in() -> Future<bool>;

    /// The user_id of the client
    fn user_id() -> Future<Result<string>>;

    // The device_id of the client
    fn device_id() -> Future<Result<string>>;

    /// The display_name of the client
    fn display_name() -> Future<Result<string>>;

    /// The avatar of the client
    fn avatar() -> Future<Result<buffer<u8>>>;

    /// The conversations the user is involved in
    fn conversations() -> Vec<Room>;
}