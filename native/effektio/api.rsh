
/// Initialize logging
fn init_logging(filter: Option<string>) -> Result<()>;

/// Create a new client for homeserver at url with storage at data_path
fn login_new_client(basepath: string, username: string, password: string) -> Future<Result<Client>>;

/// Create a new client from the restore token
fn login_with_token(basepath: string, restore_token: string) -> Future<Result<Client>>;


fn echo(inp: string) -> Result<string>;

/// Main entry point for `effektio`.
object Client {
    // Special
    /// Get the restore token for this session
    fn restore_token() -> Future<Result<string>>;

    // Regular Rust Matrix Client
    /// Whether the client is logged in
    fn logged_in() -> Future<bool>;

    /// The user_id of the client
    fn user_id() -> Future<Result<string>>;

    // The device_id of the client
    fn device_id() -> Future<Result<string>>;

    /// The display_name of the client
    fn display_name() -> Future<Result<string>>;

    // The avatar of the client
    fn avatar() -> Future<Result<Vec<u8>>>;
}