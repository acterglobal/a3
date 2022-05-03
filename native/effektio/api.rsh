
/// Initialize logging
fn init_logging(filter: Option<string>) -> Result<()>;

/// Create a new client for homeserver at url with storage at data_path
fn login_new_client(basepath: string, username: string, password: string) -> Future<Result<Client>>;

/// Create a new client from the restore token
fn login_with_token(basepath: string, restore_token: string) -> Future<Result<Client>>;

/// Create a new client anonymous client connecting to the homeserver
fn guest_client(basepath: string, homeserver: string) -> Future<Result<Client>>;

/// Create a new client from the restore token
fn register_with_registration_token(basepath: string, username: string, password: string, registration_token: string) -> Future<Result<Client>>;

object UserId {}

object AnyMessage { }

/// Timeline with Room Events
object TimelineStream {
    /// Fires whenever a new event arrived
    fn next() -> Future<Result<AnyMessage>>;

    /// Get the next count messages backwards,
    fn paginate_backwards(count: u64) -> Future<Result<Vec<AnyMessage>>>;

}

object Conversation {
    /// Calculate the display name
    fn display_name() -> Future<Result<string>>;

    /// The avatar of the room
    fn avatar() -> Future<Result<buffer<u8>>>;

    /// the members currently in the room
    fn active_members() -> Future<Result<Vec<Member>>>;

    /// Get the timeline for the room
    fn timeline() -> Future<Result<TimelineStream>>;

    // the members currently in the room
    // fn get_member(user: UserId) -> Future<Result<Member>>;
}

object Group {
    /// Calculate the display name
    fn display_name() -> Future<Result<string>>;

    /// The avatar of the Group
    fn avatar() -> Future<Result<buffer<u8>>>;

    /// the members currently in the group
    fn active_members() -> Future<Result<Vec<Member>>>;

    // the members currently in the room
    // fn get_member(user: UserId) -> Future<Result<Member>>;
}

object Member {

    /// The avatar of the member
    fn avatar() -> Future<Result<buffer<u8>>>;

    /// Calculate the display name
    fn display_name() -> Option<string>;

    /// Falback name
    // fn name() -> string;

    /// Full user_id
    fn user_id() -> UserId;

}

object Account {
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

    /// Whether the client is logged in
    fn logged_in() -> Future<bool>;

    /// return the account of the logged in user, if given
    fn account() -> Future<Result<Account>>;

    // The device_id of the client
    fn device_id() -> Future<Result<string>>;

    /// The user_id of the client
    /// deprecated, please use account() instead.
    fn user_id() -> Future<Result<string>>;

    /// The display_name of the client
    /// deprecated, please use account() instead.
    fn display_name() -> Future<Result<string>>;

    /// The avatar of the client
    /// deprecated, please use account() instead.
    fn avatar() -> Future<Result<buffer<u8>>>;

    /// The conversations the user is involved in
    fn conversations() -> Future<Result<Vec<Conversation>>>;

    /// The groups the user is part of
    fn groups() -> Future<Result<Vec<Group>>>;
}
