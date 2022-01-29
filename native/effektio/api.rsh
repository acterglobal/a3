
/// Initialize logging
fn init_logging(filter: Option<string>) -> Result<()>;

/// Create a new client for homeserver at url with storage at data_path
fn login_new_client(basepath: string, username: string, password: string) -> Future<Result<Client>>;

/// Create a new client from the restore token
fn login_with_token(basepath: string, restore_token: string) -> Future<Result<Client>>;

/// Create a new client anonymous client connecting to the homeserver
fn guest_client(basepath: string, homeserver: string) -> Future<Result<Client>>;

object Room {

}


fn echo(inp: string) -> Result<string>;

/// Main entry point for `effektio`.
object Client {
    // Special

    /// Get the restore token for this session
    fn restore_token() -> Future<Result<string>>;

    /// Whether the client is registered as a guest account
    fn is_guest() -> bool;

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
    fn avatar() -> Future<Result<Vec<u8>>>;

    /// The rooms currently known to the client
    // fn rooms() -> Future<Result<Vec<Room>>>;

    /// The get room known to the client
    fn room(room_id: string) -> Future<Result<Room>>;
}